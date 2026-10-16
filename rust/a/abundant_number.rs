#[no_mangle]
pub extern "C" fn abundant_number(n: i64) -> i64 {
    if !(1..=100_000_000).contains(&n) { return -1; }
    if n == 1 { return 0; }
    let mut sum = 1i64;
    let mut divisor = 2i64;
    while divisor <= n / divisor {
        if n % divisor == 0 {
            sum += divisor;
            let partner = n / divisor;
            if partner != divisor { sum += partner; }
            if sum > n { return 1; }
        }
        divisor += 1;
    }
    0
}
