package number_of_ways_to_select_buildings

import "core:c"

MAX_LENGTH :: 4096

count_for_target :: proc "c" (values: [^]i64, length: int, target: i64) -> i64 {
	first_count := i64(0)
	middle_count := i64(0)
	ways := i64(0)
	for index := 0; index < length; index += 1 {
		if values[index] == target {
			ways += middle_count
			first_count += 1
		} else {
			middle_count += first_count
		}
	}
	return ways
}

// Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
@(export)
number_of_ways_to_select_buildings :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 do return 0
	if values == nil || length > MAX_LENGTH do return -1
	n := int(length)
	for index := 0; index < n; index += 1 {
		if values[index] != 48 && values[index] != 49 do return -1
	}
	return count_for_target(values, n, 48) + count_for_target(values, n, 49)
}
