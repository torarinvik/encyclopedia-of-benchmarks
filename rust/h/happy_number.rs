/// Standard happy-number test using Floyd cycle detection.
fn digit_square_sum(mut n: i64) -> i64 {
    let mut total = 0;
    while n > 0 {
        let digit = n % 10;
        total += digit * digit;
        n /= 10;
    }
    total
}

#[no_mangle]
pub extern "C" fn happy_number(n: i64) -> i64 {
    if n <= 0 { return -1; }
    let mut slow = digit_square_sum(n);
    let mut fast = digit_square_sum(digit_square_sum(n));
    while slow != fast {
        slow = digit_square_sum(slow);
        fast = digit_square_sum(digit_square_sum(fast));
    }
    i64::from(slow == 1)
}
