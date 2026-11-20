const MAX_PRIME: i64 = 4093;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn power_mod(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() != 1 { return Err(()); }
    let prime = input[0];
    if prime < 2 || prime > MAX_PRIME || !is_prime(prime) { return Err(()); }
    if prime == 2 { return Ok(1); }

    let mut factors = [0i64; 16];
    let mut factor_count = 0usize;
    let mut remaining = prime - 1;
    let mut divisor = 2;
    while divisor * divisor <= remaining {
        if remaining % divisor == 0 {
            factors[factor_count] = divisor;
            factor_count += 1;
            while remaining % divisor == 0 { remaining /= divisor; }
        }
        divisor += 1;
    }
    if remaining > 1 {
        factors[factor_count] = remaining;
        factor_count += 1;
    }

    for candidate in 2..prime {
        let mut valid = true;
        for &factor in &factors[..factor_count] {
            if power_mod(candidate, (prime - 1) / factor, prime) == 1 {
                valid = false;
                break;
            }
        }
        if valid { return Ok(candidate); }
    }
    Err(())
}

#[no_mangle]
pub unsafe extern "C" fn primitive_root_factorization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
