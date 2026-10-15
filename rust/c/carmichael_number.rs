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
    if exponent == 0 { return 1; }
    let half = modular_power(base, exponent / 2, modulus) % modulus;
    let mut result = (half * half) % modulus;
    if exponent % 2 != 0 { result = (result * base) % modulus; }
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
