/// Carmichael's universal exponent by prime-power factorization.
const MAX_N: i64 = 1_024;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn lcm_i64(left: i64, right: i64) -> i64 {
    left / gcd_i64(left, right) * right
}

fn prime_power_lambda(prime: i64, exponent: usize, power: i64) -> i64 {
    if prime == 2 {
        if exponent == 1 { return 1; }
        if exponent == 2 { return 2; }
        return power / 4;
    }
    (power / prime) * (prime - 1)
}

fn factorization_lambda(n: i64) -> i64 {
    if n == 1 { return 1; }
    let mut remaining = n;
    let mut result = 1i64;
    let mut prime = 2i64;
    while prime * prime <= remaining {
        if remaining % prime != 0 {
            prime = if prime == 2 { 3 } else { prime + 2 };
            continue;
        }
        let mut exponent = 0usize;
        let mut power = 1i64;
        while remaining % prime == 0 {
            remaining /= prime;
            power *= prime;
            exponent += 1;
        }
        result = lcm_i64(result, prime_power_lambda(prime, exponent, power));
        prime = if prime == 2 { 3 } else { prime + 2 };
    }
    if remaining > 1 {
        result = lcm_i64(result, remaining - 1);
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn carmichael_lambda_function(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    let n = *input;
    if n < 1 || n > MAX_N || length != 1 { return -1; }
    factorization_lambda(n)
}
