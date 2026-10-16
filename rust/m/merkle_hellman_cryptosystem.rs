fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn add_mod(a: u64, b: u64, modulus: u64) -> u64 {
    if a >= modulus - b { a - (modulus - b) } else { a + b }
}

fn mul_mod(mut a: u64, mut b: u64, modulus: u64) -> u64 {
    let mut result = 0;
    a %= modulus;
    while b != 0 {
        if b & 1 != 0 { result = add_mod(result, a, modulus); }
        b >>= 1;
        if b != 0 { a = add_mod(a, a, modulus); }
    }
    result
}

fn inverse_mod(value: u64, modulus: u64) -> u64 {
    let (mut old_r, mut r) = (modulus, value % modulus);
    let (mut old_t, mut t) = (0, 1);
    while r != 0 {
        let quotient = old_r / r;
        let next_r = old_r % r;
        let product = mul_mod(quotient % modulus, t, modulus);
        let next_t = if old_t >= product { old_t - product } else { modulus - (product - old_t) };
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    old_t
}

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn merkle_hellman_cryptosystem(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 12 || length > 43 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=127).contains(&values[0]) || !(1..=32).contains(&values[10]) { return -1; }
    let draw_count = values[10] as usize;
    if length != 11 + draw_count { return -1; }

    let mut easy = [0u64; 8];
    let mut sum = 1u64 << 32;
    for index in 0..8 {
        if !(0..=(u32::MAX as i64)).contains(&values[1 + index]) { return -1; }
        easy[index] = sum + values[1 + index] as u64;
        sum += easy[index];
    }
    if !(0..=(u32::MAX as i64)).contains(&values[9]) { return -1; }
    let modulus = sum + values[9] as u64;
    for index in 0..draw_count {
        let draw_value = values[11 + index];
        if draw_value < 0 || draw_value as u64 > modulus { return -1; }
        let divisor = gcd(draw_value as u64, modulus);
        if index + 1 < draw_count && divisor == 1 { return -1; }
        if index + 1 == draw_count && divisor != 1 { return -1; }
    }
    if output.is_null() || capacity < 17 { return -2; }

    let multiplier = values[10 + draw_count] as u64;
    let mut hard = [0u64; 8];
    for index in 0..8 { hard[index] = mul_mod(multiplier, easy[index], modulus); }
    let message = values[0] as u64;
    let mut ciphertext = 0u64;
    for bit_index in (0..=7).rev() {
        if (message >> bit_index) & 1 != 0 { ciphertext += hard[7 - bit_index]; }
    }

    let inverse = inverse_mod(multiplier, modulus);
    let mut residue = mul_mod(inverse, ciphertext % modulus, modulus);
    let mut decoded = 0u8;
    for index in 0..8 {
        let weight = easy[7 - index];
        if residue >= weight {
            residue -= weight;
            decoded |= 1 << index;
        }
    }
    if residue != 0 || decoded as u64 != message { return -1; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 17) };
    put_i64(out, 0, ciphertext as i64);
    put_i64(out, 8, 1);
    out[16] = decoded;
    17
}
