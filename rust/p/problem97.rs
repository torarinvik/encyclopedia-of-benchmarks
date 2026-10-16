/// Return the unpadded decimal suffix of the non-Mersenne prime expression.
const MAX_DIGITS: i64 = 18;
const POWER_EXPONENT: i64 = 7_830_457;

fn multiply_mod(left_value: i64, right_value: i64, modulus: i64) -> i64 {
    let mut left = left_value;
    let mut right = right_value;
    let mut result = 0i64;
    while right > 0 {
        if right % 2 != 0 { result = (result + left) % modulus; }
        left = (left + left) % modulus;
        right /= 2;
    }
    result
}

#[no_mangle]
pub extern "C" fn problem97(digits: i64) -> i64 {
    if digits < 0 || digits > MAX_DIGITS { return -1; }
    let mut modulus = 1i64;
    for _ in 0..digits { modulus *= 10; }
    let mut power = 1 % modulus;
    let mut base = 2 % modulus;
    let mut exponent = POWER_EXPONENT;
    while exponent > 0 {
        if exponent % 2 != 0 { power = multiply_mod(power, base, modulus); }
        base = multiply_mod(base, base, modulus);
        exponent /= 2;
    }
    (multiply_mod(28_433, power, modulus) + 1) % modulus
}
