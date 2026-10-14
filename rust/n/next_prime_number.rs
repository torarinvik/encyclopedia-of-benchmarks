/// Find the smallest prime strictly greater than the input.
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
pub extern "C" fn next_prime_number(value: i64) -> i64 {
    if !(-4096..=4096).contains(&value) { return -1; }
    let mut candidate = value + 1;
    if candidate < 2 { candidate = 2; }
    while !is_prime(candidate) { candidate += 1; }
    candidate
}
