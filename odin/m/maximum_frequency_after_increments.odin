package maximum_frequency_after_increments

import "core:c"

// Sort values, then grow the longest affordable window.
@(export)
maximum_frequency_after_increments :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 257 do return -1
    budget := input[0]
    count := int(length - 1)
    if budget < 0 || budget > 1_000_000 do return -1
    values: [256]i64 = {}
    for index := 0; index < count; index += 1 {
        value := input[index + 1]
        if value < 1 || value > 10_000 do return -1
        position := index
        for position > 0 && values[position - 1] > value {
            values[position] = values[position - 1]
            position -= 1
        }
        values[position] = value
    }
    left := 0
    window_sum := i64(0)
    best := 0
    for right := 0; right < count; right += 1 {
        window_sum += values[right]
        for values[right] * i64(right - left + 1) - window_sum > budget {
            window_sum -= values[left]
            left += 1
        }
        window_length := right - left + 1
        if window_length > best do best = window_length
    }
    return i64(best)
}
