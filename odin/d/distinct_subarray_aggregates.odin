package distinct_subarray_aggregates

import "core:c"

MAX_N :: 64
MAX_INPUT :: 67
MAX_SEGMENTS :: 65

gcd_nonnegative :: proc(a_value, b_value: i64) -> i64 {
	a, b := a_value, b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

combine_value :: proc(mode, a, b: i64) -> i64 {
	if mode == 0 do return gcd_nonnegative(a, b)
	if mode == 1 do return a | b
	return a & b
}

@(export)
distinct_subarray_aggregates :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	mode, n_value := input[0], input[1]
	if mode < 0 || mode > 2 || n_value < 0 || n_value > MAX_N do return -1
	n := int(n_value)
	if int(length) != 2 + n do return -1

	segment_value: [MAX_SEGMENTS]i64 = 0
	segment_left: [MAX_SEGMENTS]i64 = 0
	segment_right: [MAX_SEGMENTS]i64 = 0
	segment_count := 0
	aggregate_sum: i64 = 0
	suffix_distinct_count: i64 = 0
	for right := 0; right < n; right += 1 {
		value := input[2+right]
		if value < 0 || value > 255 do return -1
		for j := 0; j < segment_count; j += 1 {
			segment_value[j] = combine_value(mode, segment_value[j], value)
		}
		segment_value[segment_count] = value
		segment_left[segment_count] = i64(right)
		segment_right[segment_count] = i64(right)
		segment_count += 1

		write := 0
		for read := 0; read < segment_count; read += 1 {
			if write > 0 && segment_value[read] == segment_value[write-1] {
				segment_right[write-1] = segment_right[read]
			} else {
				segment_value[write] = segment_value[read]
				segment_left[write] = segment_left[read]
				segment_right[write] = segment_right[read]
				write += 1
			}
		}
		segment_count = write
		suffix_distinct_count += i64(segment_count)
		for j := 0; j < segment_count; j += 1 {
			aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1)
		}
	}
	return aggregate_sum * 1024 + suffix_distinct_count
}
