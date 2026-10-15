fn sum_divisors(number: u64) -> i64 {
    let mut sum = 0i64;
    let mut divisor = 1u64;
    while divisor * divisor <= number {
        if number % divisor == 0 {
            sum += divisor as i64;
            let other = number / divisor;
            if other != divisor { sum += other as i64; }
        }
        divisor += 1;
    }
    sum
}

#[no_mangle]
pub extern "C" fn friendly_number(a: u64, b: u64) -> i64 {
    if a > 1_000_000 || b > 1_000_000 { return -1; }
    if a == 0 || b == 0 { return 0; }
    let sigma_a = sum_divisors(a);
    let sigma_b = sum_divisors(b);
    if sigma_a * b as i64 == sigma_b * a as i64 { 1 } else { 0 }
}
