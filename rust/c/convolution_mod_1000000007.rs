const MODULUS: i64 = 1_000_000_007;
const P1: i64 = 998_244_353;
const P2: i64 = 1_004_535_809;
const P3: i64 = 469_762_049;
const MAX_LENGTH: usize = 64;
const NTT_SIZE: usize = 128;
const MAX_RESULT: usize = 2 * MAX_LENGTH - 1;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_LENGTH;

fn power_mod(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 {
            result = result * base % modulus;
        }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

fn transform(values: &mut [i64; NTT_SIZE], n: usize, modulus: i64, inverse: bool) {
    let mut j = 0;
    for i in 1..n {
        let mut bit = n >> 1;
        while j & bit != 0 {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if i < j { values.swap(i, j); }
    }
    let mut stage = 2;
    while stage <= n {
        let mut root = power_mod(3, (modulus - 1) / stage as i64, modulus);
        if inverse { root = power_mod(root, modulus - 2, modulus); }
        let mut start = 0;
        while start < n {
            let mut factor = 1;
            for offset in 0..stage / 2 {
                let left = values[start + offset];
                let right = values[start + offset + stage / 2] * factor % modulus;
                values[start + offset] = (left + right) % modulus;
                values[start + offset + stage / 2] = (left - right + modulus) % modulus;
                factor = factor * root % modulus;
            }
            start += stage;
        }
        stage *= 2;
    }
    if inverse {
        let scale = power_mod(n as i64, modulus - 2, modulus);
        for value in &mut values[..n] { *value = *value * scale % modulus; }
    }
}

fn convolution_residues(input: *const i64, n: usize, m: usize, transform_length: usize,
    result_length: usize, modulus: i64) -> [i64; MAX_RESULT] {
    let mut a = [0; NTT_SIZE];
    let mut b = [0; NTT_SIZE];
    for i in 0..n { a[i] = unsafe { *input.add(2 + i) } % modulus; }
    for i in 0..m { b[i] = unsafe { *input.add(2 + n + i) } % modulus; }
    transform(&mut a, transform_length, modulus, false);
    transform(&mut b, transform_length, modulus, false);
    for i in 0..transform_length { a[i] = a[i] * b[i] % modulus; }
    transform(&mut a, transform_length, modulus, true);
    let mut result = [0; MAX_RESULT];
    result[..result_length].copy_from_slice(&a[..result_length]);
    result
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn convolution_mod_1000000007(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(1..=MAX_LENGTH as i64).contains(&n_value)
        || !(1..=MAX_LENGTH as i64).contains(&m_value) { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + n + m { return -1; }
    for i in 0..n + m {
        let coefficient = *input.add(2 + i);
        if !(0..MODULUS).contains(&coefficient) { return -1; }
    }
    let result_length = n + m - 1;
    let mut transform_length = 1;
    while transform_length < result_length { transform_length *= 2; }
    let output_bytes = 8 * result_length;
    if output.is_null() || capacity < output_bytes { return -2; }

    let r1 = convolution_residues(input, n, m, transform_length, result_length, P1);
    let r2 = convolution_residues(input, n, m, transform_length, result_length, P2);
    let r3 = convolution_residues(input, n, m, transform_length, result_length, P3);
    let inv1 = power_mod(P1 % P2, P2 - 2, P2);
    let p12mod3 = (P1 % P3) * (P2 % P3) % P3;
    let inv12 = power_mod(p12mod3, P3 - 2, P3);
    let p1mod = P1 % MODULUS;
    let p12mod = p1mod * (P2 % MODULUS) % MODULUS;
    for i in 0..result_length {
        let t1 = ((r2[i] - r1[i] % P2 + P2) % P2) * inv1 % P2;
        let x12 = (r1[i] % P3 + (P1 % P3) * (t1 % P3)) % P3;
        let t2 = ((r3[i] - x12 + P3) % P3) * inv12 % P3;
        let value = (r1[i] + p1mod * (t1 % MODULUS) + p12mod * (t2 % MODULUS)) % MODULUS;
        store_i64_le(output, 8 * i, value);
    }
    output_bytes as i64
}
