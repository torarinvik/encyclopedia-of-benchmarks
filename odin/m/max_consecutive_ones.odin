package max_consecutive_ones

import "core:c"

// Return the longest run of ones in a binary array.
@(export)
max_consecutive_ones :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    best := c.size_t(0)
    run := c.size_t(0)
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] != 0 && values[index] != 1 do return -1
        if values[index] == 1 {
            run += 1
            if run > best do best = run
        } else {
            run = 0
        }
    }
    return i64(best)
}
