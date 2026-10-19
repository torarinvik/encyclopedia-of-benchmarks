fn power_using_recursion_value(base: i64, exponent: i64) -> i64 {
    if exponent == 0 {
        return 1;
    }
    base * power_using_recursion_value(base, exponent - 1)
}

#[no_mangle]
pub unsafe extern "C" fn power_using_recursion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 {
        return -1;
    }
    let base = *input;
    let exponent = *input.add(1);
    if !(-10..=10).contains(&base) || !(0..=15).contains(&exponent) {
        return -1;
    }
    power_using_recursion_value(base, exponent)
}
