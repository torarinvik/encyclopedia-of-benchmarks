fn power_recursive(base: i64, exponent: i64) -> i64 {
    if exponent == 0 { return 1; }
    base * power_recursive(base, exponent - 1)
}

#[no_mangle]
pub unsafe extern "C" fn power_using_recursion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let base = values[0];
    let exponent = values[1];
    if !(-10..=10).contains(&base) || !(0..=15).contains(&exponent) { return -1; }
    power_recursive(base, exponent)
}
