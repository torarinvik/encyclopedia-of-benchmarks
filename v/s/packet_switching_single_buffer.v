module packet_switching_single_buffer

const max_packets = 16
const max_slots = 8
const max_input = 38
const max_output_bytes = 64
const beta = i64(15)

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn erase_packet(mut ids [max_packets]i64, mut values [max_packets]i64, mut count int, index int) {
	for position in index .. count - 1 {
		ids[position] = ids[position + 1]
		values[position] = values[position + 1]
	}
	count--
}

@[export: 'packet_switching_single_buffer']
pub fn packet_switching_single_buffer(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		mode, buffer, beta_value, slots_value, count_value := input[0], input[1], input[2], input[3], input[4]
		if mode < 0 || mode > 2 || buffer < 1 || buffer > 4 || slots_value < 1 || slots_value > max_slots ||
			count_value < 0 || count_value > max_packets || length != usize(5 + 2*count_value) ||
			(mode == 0 && beta_value != 0) || (mode != 0 && beta_value != beta) { return -1 }
		slots, packet_count := int(slots_value), int(count_value)
		mut arrival := [max_packets]i64{init: 0}
		mut packet_value := [max_packets]i64{init: 0}
		mut previous_slot := i64(-1)
		for packet in 0 .. packet_count {
			arrival[packet], packet_value[packet] = input[5+2*packet], input[6+2*packet]
			if arrival[packet] < 0 || arrival[packet] >= slots_value || arrival[packet] < previous_slot ||
				packet_value[packet] < 1 || packet_value[packet] > 100 { return -1 }
			previous_slot = arrival[packet]
		}
		mut resident_id := [max_packets]i64{init: 0}
		mut resident_value := [max_packets]i64{init: 0}
		mut schedule := [max_slots]i64{init: -1}
		mut resident_count, mut next_packet := 0, 0
		for slot in 0 .. slots {
			for next_packet < packet_count && arrival[next_packet] == i64(slot) {
				value := packet_value[next_packet]
				mut preempt := resident_count
				if mode == 1 {
					for index in 0 .. resident_count {
						if resident_value[index] * beta <= value { preempt = index; break }
					}
				} else if mode == 2 {
					for index in 0 .. resident_count {
						following_ok := index + 1 == resident_count || resident_value[index] <= resident_value[index+1]
						if resident_value[index] * beta < value && following_ok { preempt = index; break }
					}
				}
				if preempt < resident_count {
					erase_packet(mut resident_id, mut resident_value, mut resident_count, preempt)
					resident_id[resident_count], resident_value[resident_count] = i64(next_packet), value
					resident_count++
				} else if resident_count < int(buffer) {
					resident_id[resident_count], resident_value[resident_count] = i64(next_packet), value
					resident_count++
				} else {
					mut smallest := resident_value[0]
					for index in 1 .. resident_count { if resident_value[index] < smallest { smallest = resident_value[index] } }
					if value > smallest {
						mut evict := 0
						for resident_value[evict] != smallest { evict++ }
						erase_packet(mut resident_id, mut resident_value, mut resident_count, evict)
						resident_id[resident_count], resident_value[resident_count] = i64(next_packet), value
						resident_count++
					}
				}
				next_packet++
			}
			if resident_count > 0 {
				schedule[slot] = resident_id[0]
				erase_packet(mut resident_id, mut resident_value, mut resident_count, 0)
			}
		}
		output_bytes := 8 * slots
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		for slot in 0 .. slots { store_i64_le(mut staged[..], 8*slot, schedule[slot]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
