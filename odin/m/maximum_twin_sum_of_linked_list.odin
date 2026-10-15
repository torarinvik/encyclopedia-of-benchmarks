package maximum_twin_sum_of_linked_list

import "core:c"

MAX_LENGTH :: 1024

// Copy positive list values, then scan each mirrored twin pair.
@(export)
maximum_twin_sum_of_linked_list :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_LENGTH || length % 2 != 0 do return -1
	n := int(length)
	copied: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		if values[index] < 1 || values[index] > 100000 do return -1
		copied[index] = i32(values[index])
	}
	maximum := i64(0)
	for index := 0; index < n / 2; index += 1 {
		twin_sum := i64(copied[index]) + i64(copied[n - index - 1])
		if twin_sum > maximum do maximum = twin_sum
	}
	return maximum
}
