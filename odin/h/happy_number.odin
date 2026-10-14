package happy_number

import "core:c"

// Standard happy-number test using Floyd cycle detection.
digit_square_sum :: proc "contextless" (n: i64) -> i64 {
    value := n
    total: i64 = 0
    for value > 0 {
        digit := value % 10
        total += digit * digit
        value /= 10
    }
    return total
}

@(export)
happy_number :: proc "c" (n: i64) -> i64 {
    if n <= 0 do return -1
    slow := digit_square_sum(n)
    fast := digit_square_sum(digit_square_sum(n))
    for slow != fast {
        slow = digit_square_sum(slow)
        fast = digit_square_sum(digit_square_sum(fast))
    }
    return i64(slow == 1)
}
