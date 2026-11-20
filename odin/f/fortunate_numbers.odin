package fortunate_numbers

import "core:c"

MAX_N :: i64(10)
SEARCH_MAX :: i64(64)
MAX_PARSEABLE_LENGTH :: 2

is_prime_trial :: proc "contextless" (value: i64) -> bool {
    if value < 2 do return false
    for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
        if value % divisor == 0 do return false
    }
    return true
}

fortunate_term :: proc "contextless" (n: i64) -> i64 {
    primorial := i64(1)
    primes_found := i64(0)
    for candidate := i64(2); primes_found < n; candidate += 1 {
        if is_prime_trial(candidate) {
            primorial *= candidate
            primes_found += 1
        }
    }
    for offset := i64(2); offset <= SEARCH_MAX; offset += 1 {
        if is_prime_trial(primorial + offset) do return offset
    }
    return -2
}

@(export)
fortunate_numbers :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
    return fortunate_term(input[0])
}
