/// Encode the source divisor list in a lossless positive signed-i64 bit mask.
#[no_mangle]
pub unsafe extern "C" fn divisors(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 {
        return -1;
    }
    let n = *values;
    if !(1..=62).contains(&n) {
        return -1;
    }
    let mut mask = 0_u64;
    for divisor in 1..=n {
        if n % divisor == 0 {
            mask |= 1_u64 << divisor;
        }
    }
    mask as i64
}
