/// Unoptimized trial division under a bounded positive input contract.
#[no_mangle]
pub extern "C" fn prime_check_naive(n: i64) -> i64 {
    if n > 10_000 {
        return -1;
    }
    if n < 2 {
        return 0;
    }
    let mut divisor = 2_i64;
    while divisor < n {
        if n % divisor == 0 {
            return 0;
        }
        divisor += 1;
    }
    1
}
