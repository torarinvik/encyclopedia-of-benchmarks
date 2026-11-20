const MAX_N: i64 = 10;
const SEARCH_MAX: i64 = 64;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn is_prime_trial(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn fortunate_term(n: i64) -> i64 {
    let mut primorial = 1_i64;
    let mut primes_found = 0_i64;
    let mut candidate = 2_i64;
    while primes_found < n {
        if is_prime_trial(candidate) {
            primorial *= candidate;
            primes_found += 1;
        }
        candidate += 1;
    }
    let mut offset = 2_i64;
    while offset <= SEARCH_MAX {
        if is_prime_trial(primorial + offset) { return offset; }
        offset += 1;
    }
    -2
}

#[no_mangle]
pub unsafe extern "C" fn fortunate_numbers(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    if length != 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n = values[0];
    if !(1..=MAX_N).contains(&n) { return -1; }
    fortunate_term(n)
}
