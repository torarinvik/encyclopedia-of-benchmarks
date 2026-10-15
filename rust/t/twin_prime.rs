/// Return n + 2 when n and n + 2 are twin primes, otherwise -1.
fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    if value == 2 { return true; }
    if value % 2 == 0 { return false; }
    let mut divisor = 3i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

#[no_mangle]
pub extern "C" fn twin_prime(value: i64) -> i64 {
    if !(-4096..=4096).contains(&value) { return -1; }
    if is_prime(value) && is_prime(value + 2) { value + 2 } else { -1 }
}
