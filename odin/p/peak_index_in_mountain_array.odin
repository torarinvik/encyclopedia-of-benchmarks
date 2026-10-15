package peak_index_in_mountain_array

import "core:c"

MAX_ARRAY_LENGTH :: 100000

// Find the peak of a strict mountain array with binary search.
@(export)
peak_index_in_mountain_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 3 || length > MAX_ARRAY_LENGTH || (length > 0 && values == nil) do return -1
    low := 0
    high := int(length) - 1
    for low < high {
        middle := low + (high - low) / 2
        if values[middle] < values[middle + 1] { low = middle + 1 }
        else { high = middle }
    }
    if low == 0 || low + 1 == int(length) do return -1
    return i64(low)
}
