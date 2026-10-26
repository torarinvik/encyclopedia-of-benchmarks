module packet_switching_sgr_multi_queue

const max_queues = 4
const max_slots = 8
const max_input = 36
const max_output_bytes = 64

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'packet_switching_sgr_multi_queue']
pub fn packet_switching_sgr_multi_queue(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		queue_value, buffer, slots_value := input[0], input[1], input[2]
		if queue_value < 2 || queue_value > max_queues || buffer < 1 || buffer > 4 || slots_value < 1 || slots_value > max_slots { return -1 }
		queues, slots := int(queue_value), int(slots_value)
		if length != usize(3 + queues * slots) { return -1 }
		mut loads := [max_queues]i64{init: 0}
		mut peaks := [max_queues]i64{init: 0}
		mut schedule := [max_slots]i64{init: -1}
		for slot in 0 .. slots {
			for queue in 0 .. queues {
				arrivals := input[3 + slot * queues + queue]
				if arrivals < 0 || arrivals > buffer { return -1 }
				loads[queue] += arrivals
				if loads[queue] > buffer { loads[queue] = buffer }
				if loads[queue] > peaks[queue] { peaks[queue] = loads[queue] }
			}
			mut has_large, mut has_nonempty, mut has_underfull_peak := false, false, false
			for queue in 0 .. queues {
				if loads[queue] > 0 {
					has_nonempty = true
					if loads[queue] > buffer / 2 { has_large = true }
					if peaks[queue] < buffer { has_underfull_peak = true }
				}
			}
			if !has_nonempty {
				schedule[slot] = -1
				for queue in 0 .. queues { peaks[queue] = 0 }
				continue
			}
			use_history := !has_large && has_underfull_peak
			mut selected := queues
			for queue in 0 .. queues {
				if loads[queue] == 0 || (use_history && peaks[queue] >= buffer) { continue }
				if selected == queues || loads[queue] > loads[selected] { selected = queue }
			}
			schedule[slot] = i64(selected)
			loads[selected]--
			mut any_left := false
			for queue in 0 .. queues { if loads[queue] > 0 { any_left = true } }
			if !any_left { for queue in 0 .. queues { peaks[queue] = 0 } }
		}
		output_bytes := 8 * slots
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		for slot in 0 .. slots { store_i64_le(mut staged[..], 8 * slot, schedule[slot]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
