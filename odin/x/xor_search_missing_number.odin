package xor_search_missing_number

import "core:c"

MAX_N :: i64(255)
MAX_INPUT_LENGTH :: 257

@(export)
xor_search_missing_number :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
    n_value := input[0]
    if n_value < 0 || n_value > MAX_N || length != c.size_t(n_value + 1) do return -1
    n := int(n_value)
    seen: [256]bool = {}
    result := n_value
    for i := 0; i < n; i += 1 {
        value := input[i + 1]
        if value < 0 || value > n_value || seen[int(value)] do return -1
        seen[int(value)] = true
        result ^= i64(i) ^ value
    }
    return result
}
