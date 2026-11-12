const TABLE_SIZE: usize = 65_536;
const TABLE_MASK: usize = TABLE_SIZE - 1;
const MAX_MODULUS: u64 = 1_000_000_000;

fn gcd(mut left: u64, mut right: u64) -> u64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}

fn ceil_sqrt(value: u64) -> u64 {
    let (mut low, mut high) = (1u64, 31_623u64);
    while low < high {
        let middle = low + (high - low) / 2;
        if middle * middle >= value { high = middle; } else { low = middle + 1; }
    }
    low
}

fn pow_mod(mut base: u64, mut exponent: u64, modulus: u64) -> u64 {
    let mut result = 1 % modulus;
    while exponent != 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}

fn inverse_mod(value: u64, modulus: u64) -> Option<u64> {
    let (mut old_r, mut r) = (value as i64, modulus as i64);
    let (mut old_t, mut t) = (1i64, 0i64);
    while r != 0 {
        let quotient = old_r / r;
        let next_r = old_r - quotient * r;
        let next_t = old_t - quotient * t;
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    if old_r != 1 { return None; }
    let normalized = old_t.rem_euclid(modulus as i64) as u64;
    Some(normalized)
}

fn insert_baby(keys: &mut [u64], encoded_steps: &mut [u32], key: u64, step: u32) {
    let mut slot = (key as usize) & TABLE_MASK;
    while encoded_steps[slot] != 0 {
        if keys[slot] == key { return; }
        slot = (slot + 1) & TABLE_MASK;
    }
    keys[slot] = key;
    encoded_steps[slot] = step + 1;
}

fn find_baby(keys: &[u64], encoded_steps: &[u32], key: u64) -> Option<u64> {
    let mut slot = (key as usize) & TABLE_MASK;
    while encoded_steps[slot] != 0 {
        if keys[slot] == key { return Some((encoded_steps[slot] - 1) as u64); }
        slot = (slot + 1) & TABLE_MASK;
    }
    None
}

fn coprime_log(x: u64, y: u64, modulus: u64) -> i64 {
    if y == 1 % modulus { return 0; }
    let width = ceil_sqrt(modulus);
    let mut keys = vec![0u64; TABLE_SIZE];
    let mut encoded_steps = vec![0u32; TABLE_SIZE];
    let mut residue = 1 % modulus;
    for step in 0..width {
        insert_baby(&mut keys, &mut encoded_steps, residue, step as u32);
        residue = (residue * x) % modulus;
    }
    let inverse = match inverse_mod(x, modulus) { Some(value) => value, None => return -1 };
    let giant_factor = pow_mod(inverse, width, modulus);
    let mut giant = y;
    let mut block = 0u64;
    while block * width <= modulus {
        if let Some(baby) = find_baby(&keys, &encoded_steps, giant) {
            let answer = block * width + baby;
            return if answer <= modulus { answer as i64 } else { -1 };
        }
        giant = (giant * giant_factor) % modulus;
        block += 1;
    }
    -1
}

fn extended_log(x: u64, mut y: u64, mut modulus: u64) -> i64 {
    if modulus == 1 { return 0; }
    let mut accumulator = 1u64;
    let mut added = 0u64;
    while gcd(x, modulus) > 1 {
        let divisor = gcd(x, modulus);
        if y == accumulator { return added as i64; }
        if y % divisor != 0 { return -1; }
        y /= divisor;
        modulus /= divisor;
        accumulator = (accumulator * (x / divisor)) % modulus;
        added += 1;
        if modulus == 1 { return added as i64; }
    }
    let inverse = match inverse_mod(accumulator, modulus) { Some(value) => value, None => return -1 };
    let reduced_target = (y * inverse) % modulus;
    let remaining = coprime_log(x % modulus, reduced_target, modulus);
    if remaining < 0 { -1 } else { added as i64 + remaining }
}

/// Packed input `[x, y, m]`; return the least nonnegative exponent, or -1.
#[no_mangle]
pub unsafe extern "C" fn discrete_logarithm_mod(values: *const i64, length: usize) -> i64 {
    if length != 3 || values.is_null() { return -1; }
    let x = *values;
    let y = *values.add(1);
    let modulus = *values.add(2);
    if x < 0 || y < 0 || modulus < 1 || modulus as u64 > MAX_MODULUS || x >= modulus || y >= modulus {
        return -1;
    }
    extended_log(x as u64, y as u64, modulus as u64)
}
