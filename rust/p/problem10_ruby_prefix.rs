// Ruby Project Euler 10's strict cumulative-prime prefix.
fn is_prime_value(number: i64) -> bool {
    if number > 1 && number < 4 { return true; }
    if number < 2 || number % 2 == 0 || number % 3 == 0 { return false; }
    let mut divisor = 5_i64;
    while divisor * divisor <= number {
        if number % divisor == 0 || number % (divisor + 2) == 0 { return false; }
        divisor += 6;
    }
    true
}

#[no_mangle]
pub extern "C" fn problem10_ruby_prefix(max_total: i64) -> i64 {
    if !(0..=2_000_000).contains(&max_total) { return -1; }
    let mut sum = 1_i64;
    let mut value = 1_i64;
    let mut number = 2_i64;
    while number < max_total && value < max_total {
        if is_prime_value(number) {
            value += number;
            if value < max_total { sum = value; }
        }
        number += 1;
    }
    sum
}
