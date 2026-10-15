package median_of_two_sorted_arrays_partition

import "core:c"

MAX_ARRAY_LENGTH :: 1000

// Find twice the median by binary-searching a partition of the shorter sorted array.
@(export)
median_of_two_sorted_arrays_partition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 2 * MAX_ARRAY_LENGTH + 2 do return -2_000_001
	if input[0] < 0 || input[0] > MAX_ARRAY_LENGTH || input[1] < 0 || input[1] > MAX_ARRAY_LENGTH do return -2_000_001

	first_count := int(input[0])
	second_count := int(input[1])
	total_count := first_count + second_count
	if total_count == 0 || total_count > 2 * MAX_ARRAY_LENGTH || length != c.size_t(total_count + 2) do return -2_000_001
	second_start := first_count + 2
	for index := 0; index < first_count; index += 1 {
		value := input[index + 2]
		if value < -1_000_000 || value > 1_000_000 || (index > 0 && input[index + 1] > value) do return -2_000_001
	}
	for index := 0; index < second_count; index += 1 {
		value := input[second_start + index]
		if value < -1_000_000 || value > 1_000_000 || (index > 0 && input[second_start + index - 1] > value) do return -2_000_001
	}

	short_start := 2
	long_start := second_start
	short_count := first_count
	long_count := second_count
	if short_count > long_count {
		temporary_start := short_start
		short_start = long_start
		long_start = temporary_start
		temporary_count := short_count
		short_count = long_count
		long_count = temporary_count
	}
	low_cut := 0
	high_cut := short_count
	left_count := (total_count + 1) / 2
	for low_cut <= high_cut {
		first_cut := low_cut + (high_cut - low_cut) / 2
		second_cut := left_count - first_cut
		first_left := i64(-1_000_001)
		if first_cut > 0 do first_left = input[short_start + first_cut - 1]
		first_right := i64(1_000_001)
		if first_cut < short_count do first_right = input[short_start + first_cut]
		second_left := i64(-1_000_001)
		if second_cut > 0 do second_left = input[long_start + second_cut - 1]
		second_right := i64(1_000_001)
		if second_cut < long_count do second_right = input[long_start + second_cut]

		if first_left <= second_right && second_left <= first_right {
			left_max := first_left
			if second_left > left_max do left_max = second_left
			if total_count % 2 != 0 do return left_max * 2
			right_min := first_right
			if second_right < right_min do right_min = second_right
			return left_max + right_min
		}
		if first_left > second_right {
			if first_cut == 0 do return -2_000_001
			high_cut = first_cut - 1
		} else {
			low_cut = first_cut + 1
		}
	}
	return -2_000_001
}
