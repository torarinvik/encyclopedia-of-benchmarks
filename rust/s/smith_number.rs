fn is_prime(value: i64) -> bool {
    if value == 2 { return true; }
    if value < 2 || value % 2 == 0 { return false; }
    let mut divisor = 3;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

fn digit_sum(mut value: i64) -> i64 {
    let mut sum = 0;
    while value != 0 {
        sum += value % 10;
        value /= 10;
    }
    sum
}

fn prime_factor_digit_sum(value: i64) -> i64 {
    let mut sum = 0;
    let mut remainder = value;
    let mut factor = 2;
    while factor <= value / factor {
        while remainder % factor == 0 {
            sum += digit_sum(factor);
            remainder /= factor;
        }
        factor += 1;
    }
    if remainder > 1 { sum += digit_sum(remainder); }
    sum
}

#[no_mangle]
pub extern "C" fn smith_number(value: i64) -> i64 {
    if !(1..=2_147_483_647).contains(&value) { return -1; }
    if is_prime(value) { return 0; }
    i64::from(digit_sum(value) == prime_factor_digit_sum(value))
}
