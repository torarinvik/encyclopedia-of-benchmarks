package hanging_line_largest_rectangle

import "core:c"

MAX_LENGTH :: 64
MAX_HEIGHT :: i64(1_000_000)
INVALID_RESULT :: i64(-9_223_372_036_854_775_807) - 1

@(export)
hanging_line_largest_rectangle :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
	if length == 0 do return 0
	if heights == nil || length > MAX_LENGTH do return INVALID_RESULT
	for i := c.size_t(0); i < length; i += 1 {
		if heights[i] < 0 || heights[i] > MAX_HEIGHT do return INVALID_RESULT
	}

	left: [MAX_LENGTH]c.size_t
	right: [MAX_LENGTH]c.size_t
	for i := c.size_t(0); i < length; i += 1 {
		left[i] = i
		for left[i] > 0 && heights[i] <= heights[left[i] - 1] {
			left[i] = left[left[i] - 1]
		}
	}
	i := length
	for i > 0 {
		i -= 1
		right[i] = i
		for right[i] + 1 < length && heights[i] <= heights[right[i] + 1] {
			right[i] = right[right[i] + 1]
		}
	}

	best := i64(0)
	for j := c.size_t(0); j < length; j += 1 {
		width := i64(right[j] - left[j] + 1)
		area := heights[j] * width
		best = max(best, area)
	}
	return best
}
