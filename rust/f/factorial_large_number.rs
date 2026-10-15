/// Multiply a base-10 digit array by each factor through n.
const MAX_N: i64 = 100;
const MAX_DIGITS: usize = 160;

#[no_mangle]
pub unsafe extern "C" fn factorial_large_number(n: i64, output: *mut u8,
                                                  output_capacity: usize) -> i64 {
    if !(0..=MAX_N).contains(&n) { return -1; }
    let mut digits = [0i64; MAX_DIGITS];
    digits[0] = 1;
    let mut digit_count = 1usize;
    for factor in 2..=n {
        let mut carry = 0i64;
        for digit in digits.iter_mut().take(digit_count) {
            let product = *digit * factor + carry;
            *digit = product % 10;
            carry = product / 10;
        }
        while carry != 0 {
            digits[digit_count] = carry % 10;
            digit_count += 1;
            carry /= 10;
        }
    }
    if output.is_null() || output_capacity < digit_count { return -2; }
    for index in 0..digit_count {
        *output.add(index) = b'0' + digits[digit_count - index - 1] as u8;
    }
    digit_count as i64
}
