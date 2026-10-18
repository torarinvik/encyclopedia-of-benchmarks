const MAX_N: i64 = 1_000_005;

#[no_mangle]
pub unsafe extern "C" fn smallest_prime_factor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n = *input;
    if !(2..=MAX_N).contains(&n) { return -1; }
    let mut factor = 2_i64;
    while factor <= n / factor {
        if n % factor == 0 { return factor; }
        factor += 1;
    }
    n
}
