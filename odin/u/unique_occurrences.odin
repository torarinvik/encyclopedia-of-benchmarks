package unique_occurrences

import "core:c"

// Check whether every present value has a distinct occurrence count.
@(export)
unique_occurrences :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 do return 1
    if length > 1000 || values == nil do return -1
    n := int(length)
    first := u64(values[0])
    if n == 1 do return 1 if first + 1000 <= 2000 else -1
    largest_biased, different_bits: u64
    for index := 0; index < n; index += 1 {
        value := u64(values[index])
        different_bits |= value ~ first
        largest_biased = max(largest_biased, value + 1000)
    }
    if largest_biased > 2000 do return -1
    if different_bits == 0 do return 1

    counts: [2001]u16
    touched: [44]u16
    distinct_count := 0
    for index := 0; index < n; index += 1 {
        slot := int(values[index] + 1000)
        if counts[slot] == 0 {
            next_distinct := distinct_count + 1
            if next_distinct * (next_distinct + 1) > 2 * n do return 0
            touched[distinct_count] = u16(slot)
            distinct_count = next_distinct
        }
        counts[slot] += 1
    }
    seen: [16]u64
    for index := 0; index < distinct_count; index += 1 {
        frequency := int(counts[touched[index]])
        word := frequency >> 6
        bit := u64(1) << u32(frequency & 63)
        if (seen[word] & bit) != 0 do return 0
        seen[word] |= bit
    }
    return 1
}
