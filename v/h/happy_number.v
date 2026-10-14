module happy_number

// Standard happy-number test using Floyd cycle detection.
fn digit_square_sum(n i64) i64 {
    mut value := n
    mut total := i64(0)
    for value > 0 {
        digit := value % 10
        total += digit * digit
        value /= 10
    }
    return total
}

@[export: 'happy_number']
pub fn happy_number(n i64) i64 {
    if n <= 0 { return -1 }
    mut slow := digit_square_sum(n)
    mut fast := digit_square_sum(digit_square_sum(n))
    for slow != fast {
        slow = digit_square_sum(slow)
        fast = digit_square_sum(digit_square_sum(fast))
    }
    if slow == 1 { return 1 }
    return 0
}
