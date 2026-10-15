package minimum_size_subarray_sum

import "core:c"

@(export)
minimum_size_subarray_sum :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length < 2 do return -1
	target := packed[0]
	count := packed[1]
	if target < 1 || target > 1_000_000 || count < 0 || count > 256 || length != c.size_t(count) + 2 do return -1
	for index: i64 = 0; index < count; index += 1 {
		value := packed[index + 2]
		if value < 1 || value > 1_000_000 do return -1
	}
	left: i64 = 0
	current_sum: i64 = 0
	best := count + 1
	for right: i64 = 0; right < count; right += 1 {
		current_sum += packed[right + 2]
		for current_sum >= target {
			width := right - left + 1
			if width < best do best = width
			current_sum -= packed[left + 2]
			left += 1
		}
	}
	if best <= count do return best
	return 0
}
