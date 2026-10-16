/// Preserve the pinned sigma2 behavior, including omission of divisor 1.
const MAX_LIMIT: i64 = 1000;
const MOD_LIMIT: i64 = 1_000_000_000;

fn contains(value: i64, divisors: &[i64; 128], length: usize) -> bool {
    divisors[..length].contains(&value)
}
fn get_divisors(number: i64, divisors: &mut [i64; 128]) -> usize {
    if number == 1 { divisors[0] = 1; return 1; }
    let mut count = 0usize;
    let mut divisor = 1i64;
    while divisor * divisor <= number + 1 {
        if number % divisor == 0 {
            let quotient = number / divisor;
            if !contains(divisor, divisors, count) { divisors[count] = divisor; count += 1; }
            if !contains(quotient, divisors, count) { divisors[count] = quotient; count += 1; }
        }
        divisor += 1;
    }
    count
}
fn sigma2_source(number: i64) -> i64 {
    let mut divisors = [0i64; 128];
    let count = get_divisors(number, &mut divisors);
    let mut sum = 0i64;
    for &value in divisors.iter().take(count).skip(1) { sum += (value * value) % MOD_LIMIT; }
    sum % MOD_LIMIT
}

#[no_mangle]
pub extern "C" fn problem401(limit: i64) -> i64 {
    if limit < 0 || limit > MAX_LIMIT { return -1; }
    let mut sum = 0i64;
    for number in 0..=limit { sum += sigma2_source(number); }
    sum % MOD_LIMIT
}
