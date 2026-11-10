#[no_mangle]
pub extern "C" fn keith_number(number: i64) -> i64 {
    if !(10..=999_999).contains(&number) {
        return -1;
    }

    let mut reversed = [0i64; 6];
    let mut digits = [0i64; 6];
    let mut value = number;
    let mut digit_count = 0usize;
    while value > 0 {
        reversed[digit_count] = value % 10;
        digit_count += 1;
        value /= 10;
    }
    let mut total = 0_i64;
    for i in 0..digit_count {
        digits[i] = reversed[digit_count - 1 - i];
        total += digits[i];
    }

    let mut oldest = 0usize;
    loop {
        let next = total;
        if next >= number {
            return if next == number { 1 } else { 0 };
        }
        total = total - digits[oldest] + next;
        digits[oldest] = next;
        oldest = (oldest + 1) % digit_count;
    }
}
