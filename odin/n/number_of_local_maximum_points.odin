package number_of_local_maximum_points

import "core:c"

MAX_LENGTH :: 4096
INT32_MIN_VALUE :: i64(-2_147_483_648)
INT32_MAX_VALUE :: i64(2_147_483_647)

is_local_maximum :: proc(values: [^]i64, length, index: int) -> bool {
	if index == 0 do return values[0] > values[1]
	if index == length - 1 do return values[index] > values[index - 1]
	return values[index] > values[index - 1] && values[index] > values[index + 1]
}

count_range :: proc(values: [^]i64, length, start, ending: int) -> i64 {
	if start == ending do return if is_local_maximum(values, length, start) then 1 else 0
	middle := (start + ending) / 2
	return count_range(values, length, start, middle) + count_range(values, length, middle + 1, ending)
}

// Count strict local maxima using the pinned recursive partition.
@(export)
number_of_local_maximum_points :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if values[i] < INT32_MIN_VALUE || values[i] > INT32_MAX_VALUE do return -1
	}
	if length == 1 do return 0 // Source compares the sole element with undefined.
	return count_range(values, int(length), 0, int(length) - 1)
}
