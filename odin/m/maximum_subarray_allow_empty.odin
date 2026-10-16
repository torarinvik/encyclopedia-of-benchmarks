package maximum_subarray_allow_empty

import "core:c"

MAX_LENGTH :: 1024

@(export)
maximum_subarray_allow_empty :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > c.size_t(MAX_LENGTH) || (length > 0 && values == nil) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < -2147483648 || values[index] > 2147483647 do return -1
    }
    current: i64 = 0
    best: i64 = 0
    for index := c.size_t(0); index < length; index += 1 {
        current += values[index]
        if current < 0 do current = 0
        if current > best do best = current
    }
    return best
}
