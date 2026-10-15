package search_insert_position

import "core:c"

// Return the lower-bound position in a strictly increasing signed 32-bit array.
@(export)
search_insert_position :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 257 do return -1
    target := input[0]
    if target < -2_147_483_648 || target > 2_147_483_647 do return -1
    for index := 1; index < int(length); index += 1 {
        if input[index] < -2_147_483_648 || input[index] > 2_147_483_647 do return -1
        if index > 1 && input[index - 1] >= input[index] do return -1
    }
    low := 0
    high := int(length - 1)
    for low < high {
        middle := low + (high - low) / 2
        if input[middle + 1] < target {
            low = middle + 1
        } else {
            high = middle
        }
    }
    return i64(low)
}
