const INVALID_RESULT: i64 = -1;
const MIN_KEY_SIZE: i64 = 2;
const MAX_KEY_SIZE: i64 = 20;
const MAX_DRAWS: i64 = 1024;
const MAX_PACKED_LENGTH: usize = 1027;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

struct DrawState<'a> {
    values: &'a [i64],
    cursor: usize,
    key_size: i64,
}

fn next_draw(state: &mut DrawState<'_>, low: i64, high: i64) -> Option<i64> {
    if state.cursor >= state.values.len() { return None; }
    let value = state.values[state.cursor];
    state.cursor += 1;
    if value < low || value >= high { return None; }
    Some(value)
}

fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a.abs()
}

fn power_mod_i64(base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1;
    let mut power = base % modulus;
    while exponent > 0 {
        if exponent & 1 != 0 { result = (result * power) % modulus; }
        power = (power * power) % modulus;
        exponent /= 2;
    }
    result
}

fn rabin_miller(num: i64, state: &mut DrawState<'_>) -> Option<bool> {
    let mut s = num - 1;
    let mut t = 0;
    while s % 2 == 0 { s /= 2; t += 1; }
    for _ in 0..5 {
        let base = next_draw(state, 2, num - 1)?;
        let mut value = power_mod_i64(base, s, num);
        if value != 1 {
            let mut i = 0;
            while value != num - 1 {
                if i == t - 1 { return Some(false); }
                i += 1;
                value = (value * value) % num;
            }
        }
    }
    Some(true)
}

fn is_prime_low_num(num: i64, state: &mut DrawState<'_>) -> Option<bool> {
    if num < 2 { return Some(false); }
    if num <= 997 {
        let mut divisor = 2;
        while divisor * divisor <= num {
            if num % divisor == 0 { return Some(false); }
            divisor += 1;
        }
        return Some(true);
    }
    for divisor in 2..=997 {
        if num % divisor == 0 { return Some(false); }
    }
    rabin_miller(num, state)
}

fn generate_large_prime(state: &mut DrawState<'_>) -> Option<i64> {
    let low = 1_i64 << (state.key_size - 1);
    let high = 1_i64 << state.key_size;
    loop {
        let candidate = next_draw(state, low, high)?;
        match is_prime_low_num(candidate, state)? {
            true => return Some(candidate),
            false => {}
        }
    }
}

fn find_mod_inverse(a: i64, modulus: i64) -> i64 {
    if gcd_i64(a, modulus) != 1 { return INVALID_RESULT; }
    let (mut u1, mut u2, mut u3) = (1, 0, a);
    let (mut v1, mut v2, mut v3) = (0, 1, modulus);
    while v3 != 0 {
        let quotient = u3 / v3;
        let (next_v1, next_v2, next_v3) = (u1 - quotient * v1, u2 - quotient * v2, u3 - quotient * v3);
        (u1, u2, u3) = (v1, v2, v3);
        (v1, v2, v3) = (next_v1, next_v2, next_v3);
    }
    u1 % modulus
}

fn hash_i64(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn rsa_key_generator(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 || length > MAX_PACKED_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(packed, length);
    let key_size = values[0];
    let draw_count = values[1];
    if !(MIN_KEY_SIZE..=MAX_KEY_SIZE).contains(&key_size) || !(0..=MAX_DRAWS).contains(&draw_count) ||
        length != (2 + draw_count) as usize { return INVALID_RESULT; }
    let draw_limit = 1_i64 << key_size;
    if values[2..].iter().any(|&value| value < 2 || value >= draw_limit) { return INVALID_RESULT; }

    let mut state = DrawState { values: &values[2..], cursor: 0, key_size };
    let p = match generate_large_prime(&mut state) { Some(value) => value, None => return INVALID_RESULT };
    let q = match generate_large_prime(&mut state) { Some(value) => value, None => return INVALID_RESULT };
    let n = p * q;
    let phi = (p - 1) * (q - 1);
    let low = 1_i64 << (key_size - 1);
    let high = 1_i64 << key_size;
    let e = loop {
        let value = match next_draw(&mut state, low, high) { Some(value) => value, None => return INVALID_RESULT };
        if gcd_i64(value, phi) == 1 { break value; }
    };
    let d = find_mod_inverse(e, phi);
    let mut hash = FNV_OFFSET_BASIS;
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, e);
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, d);
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
