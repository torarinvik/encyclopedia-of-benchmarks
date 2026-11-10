fn is_composite(n: i64) -> bool {
    if n < 4 { return false; }
    let mut divisor = 2;
    while divisor <= n / divisor {
        if n % divisor == 0 { return true; }
        divisor += 1;
    }
    false
}

fn modular_power(base: i64, exponent: i64, modulus: i64) -> i64 {
    let mut result = 1;
    let mut power = base;
    let mut remaining = exponent;
    while remaining > 0 {
        if remaining % 2 != 0 { result = (result * power) % modulus; }
        remaining /= 2;
        if remaining > 0 { power = (power * power) % modulus; }
    }
    result
}

fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn carmichael_number(value: i64) -> i64 {
    if !(1..=10_000).contains(&value) { return -1; }
    if value < 3 || !is_composite(value) { return 0; }
    for base in 2..value {
        if gcd(base, value) == 1 && modular_power(base, value - 1, value) != 1 { return 0; }
    }
    1
}
