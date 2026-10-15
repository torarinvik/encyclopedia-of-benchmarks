package trapped_rainwater

import "core:c"

// Sum trapped water using per-position prefix and suffix maxima.
@(export)
trapped_rainwater :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length > 0 && heights == nil) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if heights[index] < 0 || heights[index] > 1000000 do return -1
    }
    if length < 3 do return 0

    left_max: [4096]i64
    right_max: [4096]i64
    left_max[0] = heights[0]
    for index := c.size_t(1); index < length; index += 1 {
        left_max[index] = max(left_max[index - 1], heights[index])
    }
    last := length - 1
    right_max[last] = heights[last]
    index := last
    for index > 0 {
        index -= 1
        right_max[index] = max(right_max[index + 1], heights[index])
    }

    water := i64(0)
    for index := c.size_t(0); index < length; index += 1 {
        water += min(left_max[index], right_max[index]) - heights[index]
    }
    return water
}
