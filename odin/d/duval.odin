package duval

import "core:c"

// Least cyclic shift index using Duval's linear-time scan.
@(export)
duval :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    if length == 0 do return 0
    if values == nil do return -1
    for index: c.size_t = 0; index < length; index += 1 {
        if values[index] < 0 || values[index] > 127 do return -1
    }

    i, answer := c.size_t(0), c.size_t(0)
    for i < length {
        answer = i
        j, k := i + 1, i
        for j < 2 * length && values[j % length] >= values[k % length] {
            if values[k % length] < values[j % length] do k = i
            else do k += 1
            j += 1
        }
        for i <= k do i += j - k
    }
    return i64(answer)
}
