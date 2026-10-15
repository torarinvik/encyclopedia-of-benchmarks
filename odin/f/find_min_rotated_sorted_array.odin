package find_min_rotated_sorted_array

import "core:c"

// Return the minimum in a rotation of a strictly increasing i64 array.
@(export)
find_min_rotated_sorted_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 256 do return -1
    low := 0
    high := int(length - 1)
    for low < high {
        middle := low + (high - low) / 2
        if values[middle] <= values[high] { high = middle }
        else { low = middle + 1 }
    }
    return values[low]
}
