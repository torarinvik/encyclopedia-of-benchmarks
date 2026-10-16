const MAX_VALUE: i64 = 1_000_000_000_000;

fn decimal_exponent(mut base: i64) -> i64 {
    if base < 1 { return -1; }
    let mut exponent = 0;
    while base > 1 && base % 10 == 0 {
        base /= 10;
        exponent += 1;
    }
    if base == 1 { exponent } else { -1 }
}

fn valid_base(base: i64) -> bool {
    base == 0 || decimal_exponent(base) >= 0
}

fn source_score(base: i64, exponent: i64) -> i64 {
    if base == 0 { return 0; }
    if exponent == 0 { return 1; }
    decimal_exponent(base) * exponent
}

#[no_mangle]
pub unsafe extern "C" fn largest_of_very_large_numbers(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 4 { return -2; }
    let input = std::slice::from_raw_parts(values, 4);
    if input.iter().any(|&x| !(0..=MAX_VALUE).contains(&x)) { return -2; }
    if !valid_base(input[0]) || !valid_base(input[2]) { return -2; }
    let a = source_score(input[0], input[1]);
    let b = source_score(input[2], input[3]);
    (a > b) as i64 - (a < b) as i64
}
