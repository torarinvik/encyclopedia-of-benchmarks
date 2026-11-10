/// Find the smallest prime strictly greater than the input.
fn is_candidate_prime(value: u32) -> bool {
    if value % 3 == 0 { return false; }
    let mut divisor = 5;
    while divisor * divisor <= value {
        if value % divisor == 0 || value % (divisor + 2) == 0 { return false; }
        divisor += 6;
    }
    true
}

#[no_mangle]
pub extern "C" fn next_prime_number(value: i64) -> i64 {
    if !(-4096..=4096).contains(&value) { return -1; }
    if value < 2 { return 2; }
    if value == 2 { return 3; }
    let mut candidate = ((value + 1) as u32) | 1;
    while !is_candidate_prime(candidate) { candidate += 2; }
    i64::from(candidate)
}
