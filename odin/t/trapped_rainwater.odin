package trapped_rainwater

import "core:c"

trapped_water_with_suffix :: proc "contextless" (heights: [^]i64, length: c.size_t, suffix: [^]u32) -> i64 {
    boundary := u32(0)
    for index := length; index > 0; {
        index -= 1
        raw := u64(heights[index])
        if raw > 1000000 do return -1
        boundary = max(boundary, u32(raw))
        suffix[index] = boundary
    }

    water := u32(0)
    boundary = 0
    for index := c.size_t(0); index < length; index += 1 {
        height := u32(heights[index])
        boundary = max(boundary, height)
        water += min(boundary, suffix[index]) - height
    }
    return i64(water)
}

// Sum trapped water using stored suffix maxima and a running prefix maximum.
@(export)
trapped_rainwater :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length > 0 && heights == nil) do return -1
    if length <= 16 {
        suffix: [16]u32
        return trapped_water_with_suffix(heights, length, &suffix[0])
    }
    suffix: [4096]u32
    return trapped_water_with_suffix(heights, length, &suffix[0])
}
