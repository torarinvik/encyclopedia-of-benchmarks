package mode

import "core:c"

// Find the unique mode of a bounded array of small nonnegative integers.
@(export)
mode :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length == 0 || length > 4096 do return -1
    counts: [256]u64
    for index := c.size_t(0); index < length; index += 1 {
        value := values[index]
        if value < 0 || value > 255 do return -1
        counts[int(value)] += 1
    }
    maximum: u64 = 0
    result: i64 = -1
    unique := true
    for value in 0 ..< 256 {
        if counts[value] > maximum {
            maximum = counts[value]
            result = i64(value)
            unique = true
        } else if counts[value] != 0 && counts[value] == maximum {
            unique = false
        }
    }
    return if unique { result } else { -1 }
}
