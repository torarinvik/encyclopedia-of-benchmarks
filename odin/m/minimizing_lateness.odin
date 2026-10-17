package minimizing_lateness

import "core:c"

MAX_JOBS :: 64
MAX_OUTPUT :: 4 + 12 * MAX_JOBS

Job :: struct {
	processing: i32,
	deadline: i32,
	original_index: i32,
	start_time: i32,
	lateness: i32,
}

write_i32 :: proc "contextless" (out: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 {
		out[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
minimizing_lateness :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(1 + 2 * MAX_JOBS) do return -1
	count_value := input[0]
	if count_value < 0 || count_value > i64(MAX_JOBS) || length != c.size_t(1 + 2 * count_value) do return -1
	count := int(count_value)
	jobs: [MAX_JOBS]Job
	total_processing := i64(0)
	for i := 0; i < count; i += 1 {
		processing, deadline := input[1 + 2 * i], input[2 + 2 * i]
		if processing < 0 || processing > 2147483647 || deadline < 0 || deadline > 2147483647 do return -1
		total_processing += processing
		if total_processing > 2147483647 do return -1
		jobs[i] = Job{ i32(processing), i32(deadline), i32(i), 0, 0 }
	}
	// Stable insertion sort leaves equal deadlines in their input order.
	for i := 1; i < count; i += 1 {
		item := jobs[i]
		position := i
		for position > 0 && jobs[position - 1].deadline > item.deadline {
			jobs[position] = jobs[position - 1]
			position -= 1
		}
		jobs[position] = item
	}
	start_time := i64(0)
	for i := 0; i < count; i += 1 {
		jobs[i].start_time = i32(start_time)
		finish_time := start_time + i64(jobs[i].processing)
		late := finish_time - i64(jobs[i].deadline)
		if late > 0 do jobs[i].lateness = i32(late)
		start_time = finish_time
	}
	needed := c.size_t(4 + 12 * count)
	if output == nil || capacity < needed do return -2
	payload: [MAX_OUTPUT]u8
	write_i32(&payload[0], 0, i32(count))
	for i := 0; i < count; i += 1 {
		offset := 4 + 12 * i
		write_i32(&payload[0], offset, jobs[i].original_index)
		write_i32(&payload[0], offset + 4, jobs[i].start_time)
		write_i32(&payload[0], offset + 8, jobs[i].lateness)
	}
	for i := 0; i < int(needed); i += 1 do output[i] = payload[i]
	return i64(needed)
}
