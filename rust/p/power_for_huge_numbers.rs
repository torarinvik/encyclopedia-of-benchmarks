const MAX_OUTPUT_BYTES: usize = 513;

#[no_mangle]
pub unsafe extern "C" fn power_for_huge_numbers(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let base = *input;
    let exponent = *input.add(1);
    if !(1..=10_000).contains(&base) || !(0..=128).contains(&exponent) { return -1; }

    let mut digits = [0u8; MAX_OUTPUT_BYTES];
    digits[0] = 1;
    let mut digit_count = 1usize;
    for _ in 0..exponent {
        let mut carry = 0u32;
        for digit in digits.iter_mut().take(digit_count) {
            let product = u32::from(*digit) * base as u32 + carry;
            *digit = (product % 10) as u8;
            carry = product / 10;
        }
        while carry != 0 {
            if digit_count == MAX_OUTPUT_BYTES { return -1; }
            digits[digit_count] = (carry % 10) as u8;
            digit_count += 1;
            carry /= 10;
        }
    }
    if output.is_null() || capacity < digit_count { return -2; }
    for i in 0..digit_count {
        *output.add(i) = b'0' + digits[digit_count - 1 - i];
    }
    digit_count as i64
}
