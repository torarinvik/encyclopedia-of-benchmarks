const INVALID_RESULT: i64 = i64::MIN;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 4;
const MAX_COMPONENT: i64 = 89_000_000;
const MAX_EXPONENT: i64 = 64;
#[no_mangle]
pub unsafe extern "C" fn modpow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 3 { return INVALID_RESULT; }
    let (mut base, mut exponent, modulus) = (values[0], values[1], values[2]);
    if !(0..=MAX_COMPONENT).contains(&base) || !(0..=MAX_EXPONENT).contains(&exponent)
        || !(1..=MAX_COMPONENT).contains(&modulus) { return INVALID_RESULT; }
    if exponent == 0 {
        if base == 0 { return INVALID_RESULT; }
        return 1 % modulus;
    }
    if base == 0 { return 0; }
    let mut result = 1 % modulus;
    while exponent > 0 {
        if exponent % 2 == 1 {
            result = (result * base) % modulus;
            exponent -= 1;
        } else {
            base = (base * base) % modulus;
            exponent /= 2;
        }
    }
    result
}
