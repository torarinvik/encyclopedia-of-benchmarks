const MAX_DIGITS: usize = 1001;

#[no_mangle]
pub unsafe extern "C" fn problem016_power_digit_sum(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let base = input[0];
    let exponent = input[1];
    if !(0..=9).contains(&base) || !(0..=1000).contains(&exponent) {
        return -1;
    }

    let mut digits = [0i64; MAX_DIGITS];
    let mut digit_count = 1usize;
    digits[0] = base;

    for _power in 1..exponent {
        let mut carry = 0i64;
        for index in 0..digit_count {
            let product = digits[index] * base + carry;
            digits[index] = product % 10;
            carry = product / 10;
        }
        while carry > 0 {
            if digit_count >= MAX_DIGITS {
                return -1;
            }
            digits[digit_count] = carry % 10;
            digit_count += 1;
            carry /= 10;
        }
    }

    digits[..digit_count].iter().sum()
}
