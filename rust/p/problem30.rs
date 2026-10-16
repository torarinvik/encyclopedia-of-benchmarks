fn digit_fifth_power(digit: i64) -> i64 {
    digit * digit * digit * digit * digit
}

#[no_mangle]
pub extern "C" fn problem30(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut total = 0i64;
    for number in 1_000i64..1_000_000 {
        let mut remaining = number;
        let mut digit_sum = 0i64;
        while remaining > 0 {
            digit_sum += digit_fifth_power(remaining % 10);
            remaining /= 10;
        }
        if digit_sum == number {
            total += number;
        }
    }
    total
}
