const MAX_NUMBER: i64 = 1_000_000;

fn is_prime(value: i64) -> bool {
    if value == 2 { return true; }
    if value < 2 || value % 2 == 0 { return false; }
    let mut divisor = 3i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn germain_prime_and_safe_prime(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let number = values[0];
    let selector = values[1];
    if !(1..=MAX_NUMBER).contains(&number) || !(0..=1).contains(&selector) { return -1; }
    if selector == 0 {
        return if is_prime(number) && is_prime(2 * number + 1) { 1 } else { 0 };
    }
    if (number - 1) % 2 == 0 && is_prime(number) && is_prime((number - 1) / 2) { 1 } else { 0 }
}
