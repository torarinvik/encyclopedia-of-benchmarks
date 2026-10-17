const max_values = 64
const max_input_values = usize(67)
const min_value = i64(-1_000_000)
const max_value = i64(1_000_000)

fn key_less(left i64, right i64, reverse bool) bool {
	return if reverse { left > right } else { left < right }
}

fn find_run(mut values [64]i64, start int, end int, reverse bool) int {
	if start >= end - 1 { return start + 1 }
	mut run_end := start + 1
	if key_less(values[run_end], values[start], reverse) {
		for run_end < end && key_less(values[run_end], values[run_end - 1], reverse) { run_end++ }
		mut left := start
		mut right := run_end - 1
		for left < right {
			values[left], values[right] = values[right], values[left]
			left++
			right--
		}
	} else {
		for run_end < end && !key_less(values[run_end], values[run_end - 1], reverse) { run_end++ }
	}
	return run_end
}

fn node_power(total_length int, b1 int, n1 int, b2 int, n2 int) i64 {
	a := i64(2 * b1 + n1)
	b := i64(2 * b2 + n2)
	denominator := i64(2 * total_length)
	mut power := 0
	for (a * (i64(1) << power)) / denominator == (b * (i64(1) << power)) / denominator { power++ }
	return i64(power)
}

fn merge_runs(mut values [64]i64, start1 int, end1 int, end2 int, reverse bool) {
	mut left := [64]i64{}
	mut right := [64]i64{}
	left_length := end1 - start1
	right_length := end2 - end1
	for index in 0 .. left_length { left[index] = values[start1 + index] }
	for index in 0 .. right_length { right[index] = values[end1 + index] }
	mut i := 0
	mut j := 0
	mut output := start1
	for i < left_length && j < right_length {
		take_left := if reverse { left[i] >= right[j] } else { left[i] <= right[j] }
		if take_left { values[output] = left[i]; i++ } else { values[output] = right[j]; j++ }
		output++
	}
	for i < left_length { values[output] = left[i]; i++; output++ }
	for j < right_length { values[output] = right[j]; j++; output++ }
}

fn power_sort_impl(mut values [64]i64, length int, reverse bool) {
	if length <= 1 { return }
	mut starts := [64]int{}
	mut lengths := [64]int{}
	mut powers := [64]i64{}
	mut stack_size := 0
	mut start := 0
	for start < length {
		run_end := find_run(mut values, start, length, reverse)
		mut run_length := run_end - start
		mut power := i64(0)
		if stack_size > 0 { power = node_power(length, starts[stack_size - 1], lengths[stack_size - 1], start, run_length) }
		for stack_size > 0 && powers[stack_size - 1] >= power {
			stack_size--
			previous_start := starts[stack_size]
			previous_length := lengths[stack_size]
			merge_runs(mut values, previous_start, previous_start + previous_length, run_end, reverse)
			start = previous_start
			run_length = run_end - start
			power = 0
			if stack_size > 0 { power = node_power(length, starts[stack_size - 1], lengths[stack_size - 1], start, run_length) }
		}
		starts[stack_size] = start
		lengths[stack_size] = run_length
		powers[stack_size] = power
		stack_size++
		start = run_end
	}
	for stack_size > 1 {
		stack_size--
		right_start := starts[stack_size]
		right_length := lengths[stack_size]
		stack_size--
		left_start := starts[stack_size]
		left_length := lengths[stack_size]
		merged_end := right_start + right_length
		merge_runs(mut values, left_start, left_start + left_length, merged_end, reverse)
		merged_length := merged_end - left_start
		mut power := i64(0)
		if stack_size > 0 { power = node_power(length, starts[stack_size - 1], lengths[stack_size - 1], left_start, merged_length) }
		starts[stack_size] = left_start
		lengths[stack_size] = merged_length
		powers[stack_size] = power
		stack_size++
	}
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'power_sort']
pub fn power_sort(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		reverse_value := input[0]
		count_value := input[1]
		if (reverse_value != 0 && reverse_value != 1) || count_value < 0 || count_value > i64(max_values) { return -1 }
		count := int(count_value)
		if length != usize(2 + count) { return -1 }
		mut values := [64]i64{}
		for index in 0 .. count {
			value := input[2 + index]
			if value < min_value || value > max_value { return -1 }
			values[index] = value
		}
		if count == 0 { return 0 }
		output_bytes := usize(8 * count)
		if output == nil || capacity < output_bytes { return -2 }
		power_sort_impl(mut values, count, reverse_value == 1)
		for index in 0 .. count { write_i64_le(mut output, 8 * index, values[index]) }
		return i64(output_bytes)
	}
}
