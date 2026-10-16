// Count non-bouncy positive integers with at most the requested digits.
package problem113

MAX_DIGITS :: i64(100)

choose_integer :: proc(n, r: i64) -> i64 {
    result: i64 = 1
    for i := i64(1); i <= r; i += 1 { result = result * (n + 1 - i) / i }
    return result
}

non_bouncy_exact :: proc(digits: i64) -> i64 {
    return choose_integer(8 + digits, digits) + choose_integer(9 + digits, digits) - 10
}

@(export)
problem113 :: proc "c" (num_digits: i64) -> i64 {
    if num_digits > MAX_DIGITS do return -1
    total: i64 = 0
    for digits := i64(1); digits <= num_digits; digits += 1 {
        total += non_bouncy_exact(digits)
    }
    return total
}
