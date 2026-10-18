package permutation_count

import "core:c"

@(export)
permutation_count :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
    if input == nil || input_length != 2 do return -1
    n, r := input[0], input[1]
    if n < 0 || n > 18 || r < 0 || r > 18 do return -1
    result: i64 = 1
    if r > n {
        for factor in i64(2)..=n { result *= factor }
    } else {
        for i in i64(0)..<r { result *= n - i }
    }
    return result
}
