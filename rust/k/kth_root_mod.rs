const MAX_T: usize = 8;
const MAX_K: i64 = 1_000_000_000;
const MAX_P: i64 = 1_000;

fn modular_power(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1 % modulus;
    base %= modulus;
    while exponent > 0 {
        if exponent & 1 != 0 {
            result = result * base % modulus;
        }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2;
    while divisor * divisor <= value {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn factor_distinct(mut value: i64, factors: &mut [i64; 16]) -> usize {
    let mut count = 0;
    let mut divisor = 2;
    while divisor * divisor <= value {
        if value % divisor == 0 {
            factors[count] = divisor;
            count += 1;
            while value % divisor == 0 {
                value /= divisor;
            }
        }
        divisor += 1;
    }
    if value > 1 {
        factors[count] = value;
        count += 1;
    }
    count
}

fn primitive_root(prime: i64) -> i64 {
    if prime == 2 {
        return 1;
    }
    let order = prime - 1;
    let mut factors = [0_i64; 16];
    let count = factor_distinct(order, &mut factors);
    for candidate in 2..prime {
        let mut i = 0;
        while i < count && modular_power(candidate, order / factors[i], prime) != 1 {
            i += 1;
        }
        if i == count {
            return candidate;
        }
    }
    -1
}

fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn modular_inverse(value: i64, modulus: i64) -> i64 {
    let (mut old_t, mut new_t, mut old_r, mut new_r) = (0_i64, 1_i64, modulus, value % modulus);
    while new_r != 0 {
        let quotient = old_r / new_r;
        let (next_t, next_r) = (old_t - quotient * new_t, old_r - quotient * new_r);
        old_t = new_t;
        new_t = next_t;
        old_r = new_r;
        new_r = next_r;
    }
    if old_t < 0 { old_t += modulus; }
    old_t
}

fn kth_root(exponent: i64, residue: i64, prime: i64) -> i64 {
    if exponent == 0 {
        return if residue == 1 { 0 } else { -1 };
    }
    if residue == 0 {
        return 0;
    }
    let order = prime - 1;
    let generator = primitive_root(prime);
    let mut power = 1_i64;
    let mut discrete_log = -1_i64;
    for candidate in 0..order {
        if power == residue {
            discrete_log = candidate;
            break;
        }
        power = power * generator % prime;
    }
    if discrete_log < 0 {
        return -1;
    }
    let common = gcd_i64(exponent, order);
    if discrete_log % common != 0 {
        return -1;
    }
    let reduced_order = order / common;
    let mut root_exponent = 0;
    if reduced_order > 1 {
        let inverse = modular_inverse((exponent / common) % reduced_order, reduced_order);
        root_exponent = (discrete_log / common) * inverse % reduced_order;
    }
    let root = modular_power(generator, root_exponent, prime);
    if modular_power(root, exponent, prime) == residue { root } else { -1 }
}

unsafe fn write_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn kth_root_mod(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 1 + 3 * MAX_T {
        return -1;
    }
    let t64 = *input;
    if t64 < 1 || t64 > MAX_T as i64 {
        return -1;
    }
    let t = t64 as usize;
    if length != 1 + 3 * t {
        return -1;
    }

    let mut triples = [0_i64; 3 * MAX_T];
    for i in (0..3 * t).step_by(3) {
        let exponent = *input.add(i + 1);
        let residue = *input.add(i + 2);
        let prime = *input.add(i + 3);
        if exponent < 0 || exponent > MAX_K || prime < 2 || prime > MAX_P ||
            residue < 0 || residue >= prime || !is_prime(prime) {
            return -1;
        }
        triples[i] = exponent;
        triples[i + 1] = residue;
        triples[i + 2] = prime;
    }
    let required = 8 * t;
    if output.is_null() || capacity < required {
        return -2;
    }
    for test in 0..t {
        write_i64(output, 8 * test,
            kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]));
    }
    required as i64
}
