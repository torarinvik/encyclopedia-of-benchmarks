/// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
#[no_mangle]
pub extern "C" fn sum_of_digits(input: i64) -> i64 {
    if input < i32::MIN as i64 || input > i32::MAX as i64 {
        return -1;
    }
    let mut remaining = input.unsigned_abs();
    let mut total = 0_i64;
    while remaining != 0 {
        total += (remaining % 10) as i64;
        remaining /= 10;
    }
    total
}
