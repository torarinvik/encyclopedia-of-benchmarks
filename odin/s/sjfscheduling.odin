package sjfscheduling

import "core:c"

MAX_INPUT_LENGTH :: 130
MAX_PROCESSES :: 64
MAX_OUTPUT_BYTES :: 256

write_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
sjfscheduling :: proc "c" (input: [^]i32, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	process_count_value := input[0]
	if process_count_value < 0 || process_count_value > MAX_PROCESSES ||
		length != c.size_t(1 + 2*process_count_value) do return -1
	process_count := int(process_count_value)
	arrivals: [MAX_PROCESSES]i32
	bursts: [MAX_PROCESSES]i32
	order: [MAX_PROCESSES]i32
	completed: [MAX_PROCESSES]bool
	cursor := 1
	for index := 0; index < process_count; index += 1 {
		arrival, burst := input[cursor], input[cursor+1]
		cursor += 2
		if arrival < 0 || arrival > 255 || burst < 1 || burst > 255 do return -1
		arrivals[index], bursts[index] = arrival, burst
	}

	current_time := i32(0)
	scheduled := 0
	for scheduled < process_count {
		best := process_count
		for index := 0; index < process_count; index += 1 {
			if completed[index] || arrivals[index] > current_time do continue
			if best == process_count || bursts[index] < bursts[best] ||
				(bursts[index] == bursts[best] &&
				 (arrivals[index] < arrivals[best] ||
				  (arrivals[index] == arrivals[best] && index < best))) {
				best = index
			}
		}
		if best == process_count {
			current_time += 1
		} else {
			order[scheduled] = i32(best)
			scheduled += 1
			completed[best] = true
			current_time += bursts[best]
		}
	}

	output_bytes := process_count*4
	if output == nil || output_capacity < c.size_t(output_bytes) || output_bytes > MAX_OUTPUT_BYTES do return -2
	for index := 0; index < process_count; index += 1 { write_i32_le(output, index*4, order[index]) }
	return i64(output_bytes)
}
