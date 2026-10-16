/// Generate leading decimal digits with the pinned spigot recurrence.
const MAX_DIGITS: usize = 256;
const MAX_BOXES: usize = 854;

#[no_mangle]
pub unsafe extern "C" fn spigotpi(input: *const i64, length: usize,
                                   output: *mut u8, output_capacity: usize) -> i64 {
    if length != 1 || input.is_null() || *input < 0 || *input > MAX_DIGITS as i64 { return -1; }
    let digit_count = *input as usize;
    if output.is_null() || output_capacity < digit_count { return -2; }
    if digit_count == 0 { return 0; }

    let boxes = digit_count * 10 / 3;
    let mut remainders = [0i64; MAX_BOXES];
    for item in 0..boxes { remainders[item] = 2; }
    let mut digits_held = 0usize;
    for index in 0..digit_count {
        let mut carried_over = 0i64;
        let mut sum = 0i64;
        let mut cursor = boxes;
        while cursor > 0 {
            cursor -= 1;
            let j = cursor;
            remainders[j] *= 10;
            sum = remainders[j] + carried_over;
            let denominator = (j as i64) * 2 + 1;
            let quotient = sum / denominator;
            remainders[j] = sum % denominator;
            carried_over = quotient * j as i64;
        }
        remainders[0] = sum % 10;
        let mut q = sum / 10;
        if q == 9 {
            digits_held += 1;
        } else if q == 10 {
            q = 0;
            for offset in 1..=digits_held {
                let position = index - offset;
                let digit = *output.add(position);
                *output.add(position) = if digit == b'9' { b'0' } else { digit + 1 };
            }
            digits_held = 1;
        } else {
            digits_held = 1;
        }
        *output.add(index) = b'0' + q as u8;
    }
    digit_count as i64
}
