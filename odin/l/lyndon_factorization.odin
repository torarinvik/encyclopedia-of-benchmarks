package lyndon_factorization

import "core:c"

MAX_SEQUENCE_LENGTH :: 256

@(export)
lyndon_factorization :: proc "contextless" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if length < 1 || length > MAX_SEQUENCE_LENGTH + 1 || input == nil do return -1
    if input[0] < 0 || input[0] > MAX_SEQUENCE_LENGTH || length != c.size_t(input[0]) + 1 do return -1
    n := c.size_t(input[0])
    for i := c.size_t(0); i < n; i += 1 { if input[i + 1] < 97 || input[i + 1] > 122 do return -1 }
    required := 2 * n
    if capacity < required || (required != 0 && output == nil) do return -2
    start := c.size_t(0)
    out := c.size_t(0)
    for start < n {
        candidate := start + 1
        matched := start
        for candidate < n && input[matched + 1] <= input[candidate + 1] {
            if input[matched + 1] < input[candidate + 1] { matched = start } else { matched += 1 }
            candidate += 1
        }
        factor_length := candidate - matched
        for start <= matched {
            for j := c.size_t(0); j < factor_length; j += 1 { output[out] = u8(input[start + j + 1]); out += 1 }
            output[out] = 0; out += 1
            start += factor_length
        }
    }
    return i64(out)
}
