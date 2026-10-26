package packet_switching_sgr_multi_queue

import "core:c"

MAX_QUEUES :: 4
MAX_SLOTS :: 8
MAX_INPUT :: 36
MAX_OUTPUT_BYTES :: 64

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
packet_switching_sgr_multi_queue :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	queue_value, buffer, slots_value := input[0], input[1], input[2]
	if queue_value < 2 || queue_value > MAX_QUEUES || buffer < 1 || buffer > 4 ||
		slots_value < 1 || slots_value > MAX_SLOTS do return -1
	queues, slots := int(queue_value), int(slots_value)
	if length != c.size_t(3 + queues * slots) do return -1
	loads: [MAX_QUEUES]i64
	peaks: [MAX_QUEUES]i64
	schedule: [MAX_SLOTS]i64
	for slot := 0; slot < slots; slot += 1 {
		for queue := 0; queue < queues; queue += 1 {
			arrivals := input[3 + slot*queues + queue]
			if arrivals < 0 || arrivals > buffer do return -1
			loads[queue] += arrivals
			if loads[queue] > buffer { loads[queue] = buffer }
			if loads[queue] > peaks[queue] { peaks[queue] = loads[queue] }
		}
		has_large, has_nonempty, has_underfull_peak := false, false, false
		for queue := 0; queue < queues; queue += 1 {
			if loads[queue] > 0 {
				has_nonempty = true
				if loads[queue] > buffer/2 { has_large = true }
				if peaks[queue] < buffer { has_underfull_peak = true }
			}
		}
		if !has_nonempty {
			schedule[slot] = -1
			for queue := 0; queue < queues; queue += 1 { peaks[queue] = 0 }
			continue
		}
		use_history := !has_large && has_underfull_peak
		selected := queues
		for queue := 0; queue < queues; queue += 1 {
			if loads[queue] == 0 || (use_history && peaks[queue] >= buffer) do continue
			if selected == queues || loads[queue] > loads[selected] { selected = queue }
		}
		schedule[slot] = i64(selected)
		loads[selected] -= 1
		any_left := false
		for queue := 0; queue < queues; queue += 1 { if loads[queue] > 0 { any_left = true } }
		if !any_left { for queue := 0; queue < queues; queue += 1 { peaks[queue] = 0 } }
	}
	output_bytes := 8 * slots
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for slot := 0; slot < slots; slot += 1 { store_i64_le(&staged[0], 8*slot, schedule[slot]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
