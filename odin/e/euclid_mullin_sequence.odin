package euclid_mullin_sequence

import "core:c"

MAX_PARSEABLE_LENGTH :: 2
MAX_N :: i64(8)

least_prime_factor :: proc "contextless" (value: i64) -> i64 {
    divisor := i64(2)
    for divisor <= value / divisor; divisor += 1 {
        if value % divisor == 0 do return divisor
    }
    return value
}

euclid_mullin_term :: proc "contextless" (index: i64) -> i64 {
    product := i64(1)
    term := i64(1)
    for position := i64(0); position < index; position += 1 {
        term = least_prime_factor(product + 1)
        product *= term
    }
    return term
}

@(export)
euclid_mullin_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
    return euclid_mullin_term(input[0])
}
