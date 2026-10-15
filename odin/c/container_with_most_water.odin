package container_with_most_water

import "core:c"

// Two-pointer maximum area between vertical lines.
@(export)
container_with_most_water :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if heights[index] < 0 || heights[index] > 2147483647 do return -1
    }
    if length < 2 do return 0

    left := c.size_t(0)
    right := length - 1
    best: i64 = 0
    for left < right {
        left_height := heights[left]
        right_height := heights[right]
        height := min(left_height, right_height)
        area := height * i64(right - left)
        if area > best do best = area
        if left_height <= right_height {
            left += 1
        } else {
            right -= 1
        }
    }
    return best
}
