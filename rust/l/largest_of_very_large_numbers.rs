const MAX_VALUE: i64 = 1_000_000_000_000;

fn source_score(base: i64, exponent: i64) -> f64 {
    if base == 0 { return 0.0; }
    if exponent == 0 { return 1.0; }
    exponent as f64 * (base as f64).log10()
}

fn valid_comparison_domain(base_a: i64, exponent_a: i64, base_b: i64, exponent_b: i64) -> bool {
    exponent_a == exponent_b ||
        (base_a == base_b && (base_a == 0 || ((exponent_a == 0) == (exponent_b == 0))))
}

#[no_mangle]
pub unsafe extern "C" fn largest_of_very_large_numbers(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 4 { return -2; }
    let input = std::slice::from_raw_parts(values, 4);
    if input.iter().any(|&x| !(0..=MAX_VALUE).contains(&x)) { return -2; }
    if !valid_comparison_domain(input[0], input[1], input[2], input[3]) { return -2; }
    let a = source_score(input[0], input[1]);
    let b = source_score(input[2], input[3]);
    (a > b) as i64 - (a < b) as i64
}
