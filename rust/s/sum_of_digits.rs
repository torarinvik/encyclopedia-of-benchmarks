/// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
#[no_mangle]
pub extern "C" fn sum_of_digits(input: i64) -> i64 {
    if input < i32::MIN as i64 || input > i32::MAX as i64 {
        return -1;
    }
    let magnitude = input.unsigned_abs() as u32;
    let mut remaining = magnitude;
    let mut total = 0_u32;
    while remaining >= 10 {
        let next_quotient = remaining / 10;
        remaining /= 100;
        total += next_quotient + remaining;
    }
    i64::from(magnitude - 9 * total)
}
