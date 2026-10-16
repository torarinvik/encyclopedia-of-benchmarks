const INVALID_RESULT: i64 = i64::MIN;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;

fn pow_logarithmic_value(base: i64, exponent: u64) -> i64 {
    if exponent == 0 { return 1; }
    let half = pow_logarithmic_value(base, exponent / 2);
    let square = half * half;
    if exponent % 2 == 0 { square } else { square * base }
}

#[no_mangle]
pub unsafe extern "C" fn pow_logarithmic(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 2 { return INVALID_RESULT; }
    let (base, exponent) = (values[0], values[1]);
    if !(-10..=10).contains(&base) || !(0..=15).contains(&exponent) { return INVALID_RESULT; }
    pow_logarithmic_value(base, exponent as u64)
}
