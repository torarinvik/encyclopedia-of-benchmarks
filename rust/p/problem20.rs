/// Return the sum of the decimal digits in `n!` for 0 <= n <= 100.
#[no_mangle]
pub extern "C" fn problem20(n: i64) -> i64 {
    if !(0..=100).contains(&n) {
        return -1;
    }
    let mut digits = [0i64; 200];
    digits[0] = 1;
    let mut length = 1usize;
    for factor in 2..=n {
        let mut carry = 0i64;
        for digit in digits.iter_mut().take(length) {
            let value = *digit * factor + carry;
            *digit = value % 10;
            carry = value / 10;
        }
        while carry > 0 {
            digits[length] = carry % 10;
            length += 1;
            carry /= 10;
        }
    }
    digits[..length].iter().sum()
}
