/// Scan proper divisors under the shared signed 64-bit contract.
#[no_mangle]
pub extern "C" fn aliquot_sum(n: i64) -> i64 {
    if n < 0 { return -1; }
    let mut sum = 0i64;
    let mut divisor = 1i64;
    while divisor <= n / 2 {
        if n % divisor == 0 {
            if sum > i64::MAX - divisor { return -1; }
            sum += divisor;
        }
        divisor += 1;
    }
    sum
}
