package max_subarray

import "core:c"

max_subarray_range :: proc "contextless" (values: [^]i64, start, finish: c.size_t) -> i64 {
    if finish - start == 1 do return values[start]
    middle := start + (finish - start) / 2
    left_best := max_subarray_range(values, start, middle)
    right_best := max_subarray_range(values, middle, finish)
    running := values[middle - 1]
    left_suffix := running
    index := middle - 1
    for index > start {
        index -= 1
        running += values[index]
        if running > left_suffix do left_suffix = running
    }
    running = values[middle]
    right_prefix := running
    index = middle + 1
    for index < finish {
        running += values[index]
        if running > right_prefix do right_prefix = running
        index += 1
    }
    crossing := left_suffix + right_prefix
    best := left_best
    if right_best > best do best = right_best
    if crossing > best do best = crossing
    return best
}

@(export)
max_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 1024 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < -2147483648 || values[index] > 2147483647 do return -1
    }
    return max_subarray_range(values, 0, length)
}
