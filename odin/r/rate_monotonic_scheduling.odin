package rate_monotonic_scheduling

import "core:c"

MAX_TASKS :: 8
MAX_INPUT :: 17
MAX_OUTPUT_BYTES :: 80

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
rate_monotonic_scheduling :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	count_value := input[0]
	if count_value < 1 || count_value > MAX_TASKS || length != c.size_t(1 + 2*count_value) do return -1
	count := int(count_value)
	execution: [MAX_TASKS]i64
	period: [MAX_TASKS]i64
	order: [MAX_TASKS]int
	response: [MAX_TASKS]i64
	for task := 0; task < count; task += 1 {
		execution[task], period[task] = input[1+2*task], input[2+2*task]
		if execution[task] < 1 || execution[task] > 16 || period[task] < 1 || period[task] > 32 do return -1
		order[task], response[task] = task, -1
	}
	for index := 1; index < count; index += 1 {
		key, position := order[index], index
		for position > 0 && (period[order[position-1]] > period[key] ||
			(period[order[position-1]] == period[key] && order[position-1] > key)) {
			order[position] = order[position-1]
			position -= 1
		}
		order[position] = key
	}

	schedulable, failed_task := i64(1), i64(-1)
	for rank := 0; rank < count; rank += 1 {
		target := order[rank]
		remaining_target, elapsed := execution[target], i64(0)
		active: [MAX_TASKS]i64
		for remaining_target > 0 && elapsed < period[target] {
			for higher_rank := 0; higher_rank < rank; higher_rank += 1 {
				higher := order[higher_rank]
				if elapsed % period[higher] == 0 { active[higher] += execution[higher] }
			}
			selected := -1
			for higher_rank := 0; higher_rank < rank; higher_rank += 1 {
				higher := order[higher_rank]
				if active[higher] > 0 { selected = higher; break }
			}
			if selected >= 0 { active[selected] -= 1 } else { remaining_target -= 1 }
			elapsed += 1
		}
		if remaining_target > 0 { schedulable, failed_task = 0, i64(target); break }
		response[target] = elapsed
	}

	output_bytes := 8*(count+2)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	store_i64_le(&staged[0], 0, schedulable)
	store_i64_le(&staged[0], 8, failed_task)
	for task := 0; task < count; task += 1 { store_i64_le(&staged[0], 8*(task+2), response[task]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
