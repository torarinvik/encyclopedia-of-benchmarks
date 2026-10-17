package power_sort

import "core:c"

MAX_VALUES :: 64
MAX_INPUT_VALUES :: 67
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)

Run :: struct { start, length: int, power: i64 }

key_less :: proc(left, right: i64, reverse: bool) -> bool {
	if reverse do return left > right
	return left < right
}

find_run :: proc(values: [^]i64, start, end: int, reverse: bool) -> int {
	if start >= end - 1 do return start + 1
	run_end := start + 1
	if key_less(values[run_end], values[start], reverse) {
		for run_end < end && key_less(values[run_end], values[run_end - 1], reverse) do run_end += 1
		left, right := start, run_end - 1
		for left < right {
			temporary := values[left]
			values[left] = values[right]
			values[right] = temporary
			left += 1
			right -= 1
		}
	} else {
		for run_end < end && !key_less(values[run_end], values[run_end - 1], reverse) do run_end += 1
	}
	return run_end
}

node_power :: proc(total_length, b1, n1, b2, n2: int) -> i64 {
	a := i64(2*b1 + n1)
	b := i64(2*b2 + n2)
	denominator := i64(2 * total_length)
	power := 0
	for (a * (i64(1) << power)) / denominator == (b * (i64(1) << power)) / denominator do power += 1
	return i64(power)
}

merge_runs :: proc(values: [^]i64, start1, end1, end2: int, reverse: bool) {
	left: [MAX_VALUES]i64
	right: [MAX_VALUES]i64
	left_length := end1 - start1
	right_length := end2 - end1
	for index := 0; index < left_length; index += 1 do left[index] = values[start1 + index]
	for index := 0; index < right_length; index += 1 do right[index] = values[end1 + index]
	i, j, output := 0, 0, start1
	for i < left_length && j < right_length {
		take_left := if reverse { left[i] >= right[j] } else { left[i] <= right[j] }
		if take_left { values[output] = left[i]; i += 1 } else { values[output] = right[j]; j += 1 }
		output += 1
	}
	for i < left_length { values[output] = left[i]; i += 1; output += 1 }
	for j < right_length { values[output] = right[j]; j += 1; output += 1 }
}

power_sort_impl :: proc(values: [^]i64, length: int, reverse: bool) {
	if length <= 1 do return
	stack: [MAX_VALUES]Run
	stack_size := 0
	start := 0
	for start < length {
		run_end := find_run(values, start, length, reverse)
		run_length := run_end - start
		power := i64(0)
		if stack_size > 0 do power = node_power(length, stack[stack_size-1].start, stack[stack_size-1].length, start, run_length)
		for stack_size > 0 && stack[stack_size-1].power >= power {
			stack_size -= 1
			previous := stack[stack_size]
			merge_runs(values, previous.start, previous.start + previous.length, run_end, reverse)
			start = previous.start
			run_length = run_end - start
			power = 0
			if stack_size > 0 do power = node_power(length, stack[stack_size-1].start, stack[stack_size-1].length, start, run_length)
		}
		stack[stack_size] = Run{start, run_length, power}
		stack_size += 1
		start = run_end
	}
	for stack_size > 1 {
		stack_size -= 1
		right := stack[stack_size]
		stack_size -= 1
		left := stack[stack_size]
		merged_end := right.start + right.length
		merge_runs(values, left.start, left.start + left.length, merged_end, reverse)
		merged_length := merged_end - left.start
		power := i64(0)
		if stack_size > 0 do power = node_power(length, stack[stack_size-1].start, stack[stack_size-1].length, left.start, merged_length)
		stack[stack_size] = Run{left.start, merged_length, power}
		stack_size += 1
	}
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 do output[offset + byte] = u8((bits >> (8 * byte)) & 255)
}

@(export)
power_sort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	reverse_value, count_value := input[0], input[1]
	if (reverse_value != 0 && reverse_value != 1) || count_value < 0 || count_value > MAX_VALUES do return -1
	count := int(count_value)
	if length != c.size_t(2 + count) do return -1
	values: [MAX_VALUES]i64
	for index := 0; index < count; index += 1 {
		value := input[2 + index]
		if value < MIN_VALUE || value > MAX_VALUE do return -1
		values[index] = value
	}
	if count == 0 do return 0
	output_bytes := c.size_t(8 * count)
	if output == nil || capacity < output_bytes do return -2
	power_sort_impl(&values[0], count, reverse_value == 1)
	for index := 0; index < count; index += 1 do write_i64_le(output, 8 * index, values[index])
	return i64(output_bytes)
}
