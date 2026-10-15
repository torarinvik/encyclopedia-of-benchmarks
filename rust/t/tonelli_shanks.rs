fn mod_pow(base_value: i64, exponent_value: i64, modulus: i64) -> i64 {
    let mut base = base_value % modulus;
    let mut exponent = exponent_value;
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 {
            result = (result * base) % modulus;
        }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}

fn legendre_symbol(residue: i64, prime: i64) -> i64 {
    let symbol = mod_pow(residue % prime, (prime - 1) / 2, prime);
    if symbol == prime - 1 { -1 } else { symbol }
}

#[no_mangle]
pub extern "C" fn tonelli_shanks(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length != 2 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let mut residue = packed[0];
    let prime = packed[1];
    if prime <= 2 || prime & 1 == 0 || prime > 1_000_003 || residue < 0 || residue >= prime {
        return -1;
    }
    if residue == 0 {
        return 0;
    }
    if legendre_symbol(residue, prime) != 1 {
        return -1;
    }
    if prime % 4 == 3 {
        let root = mod_pow(residue, (prime + 1) / 4, prime);
        return root.min(prime - root);
    }
    let mut q = prime - 1;
    let mut s = 0_i64;
    while q & 1 == 0 {
        q /= 2;
        s += 1;
    }
    let mut non_residue = 2_i64;
    while legendre_symbol(non_residue, prime) != -1 {
        non_residue += 1;
    }
    let mut c = mod_pow(non_residue, q, prime);
    let mut r = mod_pow(residue, (q + 1) / 2, prime);
    let mut t = mod_pow(residue, q, prime);
    let mut remaining_s = s;
    while t != 1 {
        let mut test_power = t;
        let mut least_i = 0_i64;
        for candidate_i in 1..remaining_s {
            test_power = mod_pow(test_power, 2, prime);
            if test_power == 1 {
                least_i = candidate_i;
                break;
            }
        }
        if least_i == 0 {
            return -1;
        }
        let b = mod_pow(c, 1_i64 << (remaining_s - least_i - 1), prime);
        r = (r * b) % prime;
        c = (b * b) % prime;
        t = (t * c) % prime;
        remaining_s = least_i;
    }
    r.min(prime - r)
}
