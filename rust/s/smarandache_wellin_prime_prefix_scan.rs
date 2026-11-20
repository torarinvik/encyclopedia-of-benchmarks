const MAX_COUNT: i64 = 6;

fn is_small_prime(value: u64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2u64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn multiply_mod(left: u64, right: u64, modulus: u64) -> u64 {
    (left * right) % modulus
}

fn power_mod(mut base: u64, mut exponent: u64, modulus: u64) -> u64 {
    let mut result = 1u64;
    base %= modulus;
    while exponent != 0 {
        if exponent & 1 != 0 {
            result = multiply_mod(result, base, modulus);
        }
        exponent >>= 1;
        if exponent != 0 {
            base = multiply_mod(base, base, modulus);
        }
    }
    result
}

fn is_prime_prefix(value: u64) -> bool {
    const SMALL_PRIMES: [u64; 12] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
    const BASES: [u64; 3] = [2, 7, 61];
    if value < 2 {
        return false;
    }
    for prime in SMALL_PRIMES {
        if value == prime {
            return true;
        }
        if value % prime == 0 {
            return false;
        }
    }
    let mut odd_part = value - 1;
    let mut twos = 0u32;
    while odd_part & 1 == 0 {
        odd_part >>= 1;
        twos += 1;
    }
    for base in BASES {
        let mut witness = power_mod(base, odd_part, value);
        if witness == 1 || witness == value - 1 {
            continue;
        }
        let mut round = 1;
        while round < twos && witness != value - 1 {
            witness = multiply_mod(witness, witness, value);
            round += 1;
        }
        if witness != value - 1 {
            return false;
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn smarandache_wellin_prime_prefix_scan(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || length < 1 || length > 2 {
        return -1;
    }
    let input = std::slice::from_raw_parts(raw, length);
    if !(0..=MAX_COUNT).contains(&input[0]) || length != 1 {
        return -1;
    }

    let mut values = [0u64; 3];
    let mut result_count = 0usize;
    let mut prefix = 0u64;
    let mut candidate = 2u64;
    for _ in 0..input[0] {
        while !is_small_prime(candidate) {
            candidate += if candidate == 2 { 1 } else { 2 };
        }
        let mut scale = 10u64;
        while scale <= candidate {
            scale *= 10;
        }
        prefix = prefix * scale + candidate;
        if is_prime_prefix(prefix) {
            values[result_count] = prefix;
            result_count += 1;
        }
        candidate += if candidate == 2 { 1 } else { 2 };
    }

    let byte_count = result_count * 8;
    if output.is_null() || capacity < byte_count {
        return -2;
    }
    let staged = std::slice::from_raw_parts_mut(output, byte_count);
    for item in 0..result_count {
        for byte in 0..8 {
            staged[item * 8 + byte] = (values[item] >> (8 * byte)) as u8;
        }
    }
    byte_count as i64
}
