package maximum_subarray

import "core:c"

// Kadane's maximum nonempty contiguous-subarray sum.
@(export)
maximum_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 1024 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < -2147483648 || values[index] > 2147483647 do return -1
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
