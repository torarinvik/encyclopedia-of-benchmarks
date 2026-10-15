package longest_arithmetic_subsequence

import "core:c"

// Length of the longest arithmetic subsequence.
@(export)
longest_arithmetic_subsequence :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 64 || (length != 0 && values == nil) do return -1
    for i := c.size_t(0); i < length; i += 1 {
        if values[i] < -1_000_000 || values[i] > 1_000_000 do return -1
    }
    if length <= 1 do return i64(length)
    keys: [64][127]i64
    sizes: [64][127]i64
    maximum := i64(2)
    for right := c.size_t(0); right < length; right += 1 {
        for left := c.size_t(0); left < right; left += 1 {
            difference := values[right] - values[left]
            slot := c.size_t((difference % 127 + 127) % 127)
            for sizes[left][slot] != 0 && keys[left][slot] != difference {
                slot = (slot + 1) % 127
            }
            candidate := (if sizes[left][slot] == 0 do i64(1) else sizes[left][slot]) + 1
            slot = c.size_t((difference % 127 + 127) % 127)
            for sizes[right][slot] != 0 && keys[right][slot] != difference {
                slot = (slot + 1) % 127
            }
            if sizes[right][slot] == 0 || candidate > sizes[right][slot] {
                keys[right][slot] = difference
                sizes[right][slot] = candidate
            }
            if candidate > maximum do maximum = candidate
        }
    }
    return maximum
}
