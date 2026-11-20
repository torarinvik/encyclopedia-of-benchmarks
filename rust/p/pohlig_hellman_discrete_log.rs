/// Pohlig–Hellman logarithm with prime-order BSGS digit searches.
const MIN_P: i64 = 3;
const MAX_P: i64 = 1_009;
const MAX_PARSEABLE_LENGTH: usize = 4;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2i64;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor = if divisor == 2 { 3 } else { divisor + 2 };
    }
    true
}

fn factorize(mut value: i64) -> Vec<(i64, i64)> {
    let mut factors = Vec::new();
    let mut divisor = 2i64;
    while divisor * divisor <= value {
        if value % divisor == 0 {
            let mut exponent = 0i64;
            while value % divisor == 0 {
                value /= divisor;
                exponent += 1;
            }
            factors.push((divisor, exponent));
        }
        divisor = if divisor == 2 { 3 } else { divisor + 2 };
    }
    if value > 1 { factors.push((value, 1)); }
    factors
}

fn pow_mod(base_value: i64, exponent_value: i64, modulus: i64) -> i64 {
    let mut result = 1i64;
    let mut factor = base_value % modulus;
    let mut exponent = exponent_value;
    while exponent > 0 {
        if (exponent & 1) != 0 { result = result * factor % modulus; }
        factor = factor * factor % modulus;
        exponent >>= 1;
    }
    result
}

fn prime_order_log(generator: i64, target: i64, order: i64, modulus: i64) -> Option<i64> {
    let mut step = 1i64;
    while step * step < order { step += 1; }
    let mut baby = [0i64; 64];
    let mut value = 1i64;
    for j in 0..step as usize {
        baby[j] = value;
        value = value * generator % modulus;
    }
    let giant_factor = pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus);
    let mut probe = target;
    for i in 0..=step {
        for j in 0..step as usize {
            if baby[j] == probe {
                let candidate = i * step + j as i64;
                if candidate < order { return Some(candidate); }
            }
        }
        probe = probe * giant_factor % modulus;
    }
    None
}

fn inverse_mod(value: i64, modulus: i64) -> Option<i64> {
    let mut old_r = value;
    let mut r = modulus;
    let mut old_s = 1i64;
    let mut s = 0i64;
    while r != 0 {
        let quotient = old_r / r;
        (old_r, r) = (r, old_r - quotient * r);
        (old_s, s) = (s, old_s - quotient * s);
    }
    if old_r != 1 { return None; }
    Some(old_s.rem_euclid(modulus))
}

fn pohlig_hellman(p: i64, base: i64, target: i64) -> i64 {
    if target == 0 { return -2; }
    let p_factors = factorize(p - 1);
    let mut order = p - 1;
    for &(prime, _) in &p_factors {
        while order % prime == 0 && pow_mod(base, order / prime, p) == 1 {
            order /= prime;
        }
    }
    if order == 1 { return if target == 1 { 0 } else { -2 }; }

    let order_factors = factorize(order);
    let mut solution = 0i64;
    let mut combined_modulus = 1i64;
    for &(prime, exponent) in &order_factors {
        let mut component_modulus = 1i64;
        for _ in 0..exponent { component_modulus *= prime; }
        let mut partial_log = 0i64;
        let mut place = 1i64;
        let prime_generator = pow_mod(base, order / prime, p);
        for _ in 0..exponent {
            let current_power = pow_mod(base, partial_log, p);
            let inverse_current = pow_mod(current_power, p - 2, p);
            let residual = target * inverse_current % p;
            let digit_target = pow_mod(residual, order / (place * prime), p);
            let Some(digit) = prime_order_log(prime_generator, digit_target, prime, p) else {
                return -2;
            };
            partial_log += digit * place;
            place *= prime;
        }
        if combined_modulus == 1 {
            solution = partial_log;
            combined_modulus = component_modulus;
        } else {
            let Some(inverse) = inverse_mod(combined_modulus % component_modulus, component_modulus) else {
                return -2;
            };
            let adjustment = (partial_log - solution).rem_euclid(component_modulus)
                           * inverse % component_modulus;
            solution += combined_modulus * adjustment;
            combined_modulus *= component_modulus;
        }
    }
    solution %= order;
    if pow_mod(base, solution, p) == target { solution } else { -2 }
}

fn verify(values: &[i64]) -> i64 {
    if values.len() != 3 { return -1; }
    let p = values[0];
    let base = values[1];
    let target = values[2];
    if p < MIN_P || p > MAX_P || !is_prime(p) || base < 1 || base >= p
        || target < 0 || target >= p { return -1; }
    pohlig_hellman(p, base, target)
}

#[no_mangle]
pub unsafe extern "C" fn pohlig_hellman_discrete_log(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 3 { return -1; }
    verify(std::slice::from_raw_parts(input, length))
}
