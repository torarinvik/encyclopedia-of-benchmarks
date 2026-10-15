package harshad_number

// Return 1 when n is divisible by its base-10 digit sum, else 0.
@(export)
harshad_number :: proc "c" (n: i64) -> i64 {
    if n <= 0 || n > 2147483647 do return -1
    remaining := n
    digit_sum := i64(0)
    for remaining > 0 {
        digit_sum += remaining % 10
        remaining /= 10
    }
    if n % digit_sum == 0 do return 1
    return 0
}
