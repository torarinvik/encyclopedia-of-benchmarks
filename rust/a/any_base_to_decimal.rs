/// Fold most-significant-first digits in base 2 through 36 into i64.
#[no_mangle]
pub unsafe extern "C" fn any_base_to_decimal(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=65).contains(&length) { return -1; }
    let base = *input;
    if !(2..=36).contains(&base) { return -1; }
    let mut value = 0i64;
    for index in 1..length {
        let digit = *input.add(index);
        if digit < 0 || digit >= base { return -1; }
        if value > (i64::MAX - digit) / base { return -1; }
        value = value * base + digit;
    }
    value
}
