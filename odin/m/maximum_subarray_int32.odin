package maximum_subarray_int32

import "core:c"

MAX_LENGTH :: 1024
MAX_ABS_VALUE :: i64(1_000_000)

@(export)
maximum_subarray_int32 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length == 0 || length > c.size_t(MAX_LENGTH) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < -MAX_ABS_VALUE || values[index] > MAX_ABS_VALUE do return -1
    }
    current := values[0]
    best := current
    for index := c.size_t(1); index < length; index += 1 {
        if current > 0 {
            current += values[index]
        } else {
            current = values[index]
        }
        if current > best do best = current
    }
    return best
}
