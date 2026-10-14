package circle_sort

import "core:c"

circle_pass :: proc(values: [^]i64, low, high: c.size_t) -> bool {
	length := high - low
	if length < 2 { return false }
	swapped := false
	left := low
	right := high - 1
	for left < right {
		if values[left] > values[right] {
			temporary := values[left]
			values[left] = values[right]
			values[right] = temporary
			swapped = true
		}
		left += 1
		right -= 1
	}
	if length % 2 != 0 && left == right && right + 1 < high && values[right + 1] < values[right] {
		temporary := values[right]
		values[right] = values[right + 1]
		values[right + 1] = temporary
		swapped = true
	}
	split := low + length / 2 + length % 2
	left_swapped := circle_pass(values, low, split)
	right_swapped := circle_pass(values, split, high)
	return swapped || left_swapped || right_swapped
}

@(export)
circle_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	for length > 1 && circle_pass(values, 0, length) { }
}
