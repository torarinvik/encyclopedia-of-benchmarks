const MAX_INPUT: i64 = 9_999_999_999_999_999;

fn next_for(number: i64) -> i64 {
    let mut digits = [0_u8; 17];
    let mut remaining = number;
    let mut count = 0_usize;
    loop {
        digits[count] = (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    digits[..count].reverse();

    for left in 0..count / 2 {
        digits[count - 1 - left] = digits[left];
    }
    let mut candidate = 0_i64;
    for &digit in &digits[..count] { candidate = candidate * 10 + i64::from(digit); }
    if candidate > number { return candidate; }

    let prefix_length = (count + 1) / 2;
    let mut position = prefix_length;
    while position > 0 && digits[position - 1] == 9 {
        digits[position - 1] = 0;
        position -= 1;
    }
    if position == 0 {
        let mut power = 1_i64;
        for _ in 0..count { power *= 10; }
        return power + 1;
    }
    digits[position - 1] += 1;
    for left in 0..count / 2 {
        digits[count - 1 - left] = digits[left];
    }
    candidate = 0;
    for &digit in &digits[..count] { candidate = candidate * 10 + i64::from(digit); }
    candidate
}

#[no_mangle]
pub unsafe extern "C" fn next_palindromic_number(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let number = unsafe { *values };
    if !(0..=MAX_INPUT).contains(&number) { return -1; }
    next_for(number)
}
