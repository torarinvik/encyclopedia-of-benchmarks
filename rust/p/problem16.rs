#[no_mangle]
pub extern "C" fn problem16(exponent: i64) -> i64 {
    if !(0..=1000).contains(&exponent) {
        return -1;
    }
    let mut digits = [0i64; 400];
    digits[0] = 1;
    let mut length = 1usize;
    for _ in 0..exponent {
        let mut carry = 0i64;
        for digit in digits.iter_mut().take(length) {
            let value = *digit * 2 + carry;
            *digit = value % 10;
            carry = value / 10;
        }
        while carry > 0 {
            digits[length] = carry % 10;
            length += 1;
            carry /= 10;
        }
    }
    digits.iter().take(length).sum()
}
