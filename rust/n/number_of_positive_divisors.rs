/// Count positive divisors of the absolute value of one signed integer.
#[no_mangle]
pub extern "C" fn number_of_positive_divisors(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let value = unsafe { *values };
    if !(-1_000_000_000..=1_000_000_000).contains(&value) { return -1; }
    let mut remaining = if value < 0 { -value } else { value };
    let mut count = 1i64;
    let mut factor = 2i64;
    while factor * factor <= remaining {
        let mut exponent = 0i64;
        while remaining % factor == 0 {
            remaining /= factor;
            exponent += 1;
        }
        count *= exponent + 1;
        factor += 1;
    }
    if remaining > 1 { count *= 2; }
    count
}
