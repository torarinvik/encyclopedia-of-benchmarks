package trapped_rainwater_two_pointer

import "core:c"

MAX_LENGTH :: 4096

// Sum trapped water by advancing the side with the smaller current boundary.
@(export)
trapped_rainwater_two_pointer :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && heights == nil) do return -1
	for index := 0; index < int(length); index += 1 {
		if heights[index] < 0 || heights[index] > 1_000_000 do return -1
	}
	if length <= 2 do return 0

	left := 0
	right := int(length) - 1
	left_max: u32 = 0
	right_max: u32 = 0
	trapped: u32 = 0
	for left < right {
		if heights[left] < heights[right] {
			height := u32(heights[left])
			if height >= left_max {
				left_max = height
			} else {
				trapped += left_max - height
			}
			left += 1
		} else {
			height := u32(heights[right])
			if height >= right_max {
				right_max = height
			} else {
				trapped += right_max - height
			}
			right -= 1
		}
	}
	return i64(trapped)
}
