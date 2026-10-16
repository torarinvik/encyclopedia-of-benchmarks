/// Exact-equality reciprocal progression predicate for IEEE-754 inputs.
const MAX_VALUES: usize = 32;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn is_harmonic_series(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 || length > MAX_VALUES + 1 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let count = input[0];
    if count < 1 || count > MAX_VALUES as i64 || length != count as usize + 1 {
        return INVALID_RESULT;
    }

    let mut reciprocals = [0.0_f64; MAX_VALUES];
    for index in 0..count as usize {
        let value = f64::from_bits(input[index + 1] as u64);
        if value == 0.0 { return INVALID_RESULT; }
        reciprocals[index] = 1.0 / value;
    }
    if count == 1 { return 1.0; }
    let common_difference = reciprocals[1] - reciprocals[0];
    for index in 2..count as usize {
        if reciprocals[index] - reciprocals[index - 1] != common_difference { return 0.0; }
    }
    1.0
}
