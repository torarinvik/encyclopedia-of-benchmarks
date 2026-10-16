#[no_mangle]
pub extern "C" fn exponentiation(base: i64, exponent: i64) -> i64 {
    if !(0..=255).contains(&base) || !(0..=7).contains(&exponent) { return -1; }
    let mut result = 1i64;
    for _ in 0..exponent { result *= base; }
    result
}
