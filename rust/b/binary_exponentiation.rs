/// Exponentiation by squaring with exact signed i64 overflow detection.
#[no_mangle]
pub extern "C" fn binary_exponentiation(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (base_input, exponent_input) = (values[0], values[1]);
    if !(0..=2_147_483_647).contains(&base_input) || !(0..=2_147_483_647).contains(&exponent_input) { return -1; }
    let mut base = base_input as u64;
    let mut exponent = exponent_input as u64;
    let mut result = 1u64;
    let maximum = i64::MAX as u64;
    while exponent != 0 {
        if exponent & 1 != 0 {
            if base != 0 && result > maximum / base { return -1; }
            result *= base;
        }
        exponent >>= 1;
        if exponent != 0 {
            if base != 0 && base > maximum / base { return -1; }
            base *= base;
        }
    }
    result as i64
}
