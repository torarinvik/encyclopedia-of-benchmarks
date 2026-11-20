/// Pocklington n-1 certificate verifier for a bounded signed-integer frame.
const MAX_N: i64 = 65_535;
const MAX_FACTORS: i64 = 6;
const MAX_EXPONENT: i64 = 16;
const MAX_LENGTH: usize = 22;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2i64;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor = if divisor == 2 { 3 } else { divisor + 2 };
    }
    true
}

fn pow_mod(base: i64, exponent_value: i64, modulus: i64) -> i64 {
    let mut result = 1i64;
    let mut factor = base % modulus;
    let mut exponent = exponent_value;
    while exponent > 0 {
        if (exponent & 1) != 0 { result = (result * factor) % modulus; }
        factor = (factor * factor) % modulus;
        exponent >>= 1;
    }
    result
}

fn verify_certificate(values: &[i64]) -> i64 {
    if values.len() < 2 || values.len() > MAX_LENGTH { return -1; }
    let n = values[0];
    let count_value = values[1];
    if n < 3 || n > MAX_N || count_value < 1 || count_value > MAX_FACTORS { return -1; }
    let count = count_value as usize;
    if values.len() != 3 + 3 * count { return -1; }

    let mut factored_part = 1i64;
    let mut previous_prime = 1i64;
    for index in 0..count {
        let offset = 2 + 3 * index;
        let prime = values[offset];
        let exponent = values[offset + 1];
        let witness = values[offset + 2];
        if prime <= previous_prime || prime < 2 || exponent < 1 || exponent > MAX_EXPONENT
            || witness < 1 || witness >= n || !is_prime(prime) { return -1; }
        previous_prime = prime;
        for _ in 0..exponent {
            if factored_part > (n - 1) / prime { return -1; }
            factored_part *= prime;
        }
    }
    let cofactor = values[2 + 3 * count];
    if cofactor < 1 || cofactor >= n || factored_part * cofactor != n - 1 { return -1; }
    if factored_part * factored_part <= n { return 0; }

    for index in 0..count {
        let offset = 2 + 3 * index;
        let prime = values[offset];
        let witness = values[offset + 2];
        if pow_mod(witness, n - 1, n) != 1 { return 0; }
        let reduced = pow_mod(witness, (n - 1) / prime, n);
        let difference = (reduced + n - 1) % n;
        if gcd_i64(difference, n) != 1 { return 0; }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn pocklington_primality_certificate(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH { return -1; }
    verify_certificate(std::slice::from_raw_parts(input, length))
}
