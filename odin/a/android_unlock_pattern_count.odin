package android_unlock_pattern_count

import "core:c"

middle_point :: proc(first, second: int) -> int {
	if first == second do return -1
	first_x := first % 3
	first_y := first / 3
	second_x := second % 3
	second_y := second / 3
	delta_x := second_x - first_x
	delta_y := second_y - first_y
	if delta_x % 2 != 0 || delta_y % 2 != 0 do return -1
	middle := ((first_y + second_y) / 2) * 3 + (first_x + second_x) / 2
	if middle == first || middle == second do return -1
	return middle
}

count_from :: proc(last, visited, used, target: int) -> i64 {
	if used == target do return 1
	count: i64 = 0
	for next := 0; next < 9; next += 1 {
		bit := 1 << next
		if (visited & bit) == 0 {
			middle := middle_point(last, next)
			if middle < 0 || (visited & (1 << middle)) != 0 {
				count += count_from(next, visited | bit, used + 1, target)
			}
		}
	}
	return count
}

@(export, link_name="android_unlock_pattern_count")
android_unlock_pattern_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	target_value := input[0]
	if target_value < 4 || target_value > 9 do return -1
	target := int(target_value)
	count: i64 = 0
	for start := 0; start < 9; start += 1 {
		count += count_from(start, 1 << start, 1, target)
	}
	return count
}
