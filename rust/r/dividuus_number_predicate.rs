const MAX_N: i64 = 100_000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn sum_digits(mut value: i64) -> i64 {
    let mut sum = 0;
    while value > 0 {
        sum += value % 10;
        value /= 10;
    }
    sum
}

fn product_digits(mut value: i64) -> i64 {
    let mut product = 1;
    while value > 0 {
        product *= value % 10;
        value /= 10;
    }
    product
}

fn digital_root(mut value: i64) -> i64 {
    while value >= 10 { value = sum_digits(value); }
    value
}

fn multiplicative_root(mut value: i64) -> i64 {
    while value >= 10 { value = product_digits(value); }
    value
}

fn is_dividuus(n: i64) -> bool {
    let divisors = [sum_digits(n), product_digits(n), digital_root(n), multiplicative_root(n)];
    if divisors.iter().any(|&d| d == 0) { return false; }
    divisors.iter().all(|&d| n % d == 0)
}

#[no_mangle]
pub unsafe extern "C" fn dividuus_number_predicate(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    if length != 1 { return -1; }
    let n = unsafe { *input };
    if !(1..=MAX_N).contains(&n) { return -1; }
    if is_dividuus(n) { 1 } else { 0 }
}
