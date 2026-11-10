package trapped_rainwater_two_pointer

import "core:c"

// Process the smaller endpoint, validating each bar as it enters the window.
@(export)
trapped_rainwater_two_pointer :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length != 0 && heights == nil) do return -1
    if length == 0 do return 0

    left, right := c.size_t(0), length - 1
    left_height, right_height := u64(heights[left]), u64(heights[right])
    if left_height > 1000000 || right_height > 1000000 do return -1

    left_max, right_max, trapped: u32
    for left < right {
        if left_height < right_height {
            height := u32(left_height)
            left_max = max(left_max, height)
            trapped += left_max - height
            left += 1
            left_height = u64(heights[left])
            if left_height > 1000000 do return -1
        } else {
            height := u32(right_height)
            right_max = max(right_max, height)
            trapped += right_max - height
            right -= 1
            right_height = u64(heights[right])
            if right_height > 1000000 do return -1
        }
    }
    return i64(trapped)
}
