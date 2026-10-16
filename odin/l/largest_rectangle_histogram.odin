package largest_rectangle_histogram

import "core:c"

INVALID_RESULT :: i64(-9_223_372_036_854_775_807) - 1

@(export)
largest_rectangle_histogram :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
	if length == 0 do return 0
	if heights == nil || length > 64 do return INVALID_RESULT
	for index := c.size_t(0); index < length; index += 1 {
		if heights[index] < 0 || heights[index] > 1_000_000 do return INVALID_RESULT
	}

	stack: [64]c.size_t
	top := c.size_t(0)
	best := i64(0)
	for index := c.size_t(0); index < length; index += 1 {
		for top > 0 && heights[stack[top - 1]] > heights[index] {
			top -= 1
			bar := stack[top]
			left := c.size_t(0)
			if top > 0 do left = stack[top - 1] + 1
			area := heights[bar] * i64(index - left)
			best = max(best, area)
		}
		stack[top] = index
		top += 1
	}
	for top > 0 {
		top -= 1
		bar := stack[top]
		left := c.size_t(0)
		if top > 0 do left = stack[top - 1] + 1
		area := heights[bar] * i64(length - left)
		best = max(best, area)
	}
	return best
}
