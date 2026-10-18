package smallest_prime_factor

import "core:c"

MAX_N :: i64(1_000_005)

@(export)
smallest_prime_factor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 1 do return -1
    n := input[0]
    if n < 2 || n > MAX_N do return -1
    factor: i64 = 2
    for factor <= n/factor {
        if n%factor == 0 do return factor
        factor += 1
    }
    return n
}
