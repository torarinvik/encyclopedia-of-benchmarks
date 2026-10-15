package check_if_array_is_sorted_and_rotated

import "core:c"

// Check whether the values are a rotation of a nondecreasing array.
@(export)
check_if_array_is_sorted_and_rotated :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 256 do return -1
	for index := 0; index < int(length); index += 1 {
		if values[index] < -2_147_483_648 || values[index] > 2_147_483_647 do return -1
	}
	if length == 0 do return 1
	descents := 0
	for index := 0; index < int(length); index += 1 {
		next := (index + 1) % int(length)
		if values[index] > values[next] {
			descents += 1
			if descents > 1 do return 0
		}
	}
	return 1
}
