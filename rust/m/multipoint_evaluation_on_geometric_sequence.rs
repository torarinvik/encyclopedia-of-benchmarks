const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_M: usize = 8;
const NTT_SIZE: usize = 32;
const MAX_INPUT: usize = 12;
type Transform = [i64; NTT_SIZE];

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn ntt(values: &mut Transform, inverse: bool) {
    let mut j = 0;
    for i in 1..NTT_SIZE {
        let mut bit = NTT_SIZE / 2;
        while j & bit != 0 { j ^= bit; bit >>= 1; }
        j ^= bit;
        if i < j { values.swap(i, j); }
    }
    let mut block = 2;
    while block <= NTT_SIZE {
        let mut root = mod_pow(3, (MODULUS - 1) / block as i64);
        if inverse { root = mod_pow(root, MODULUS - 2); }
        let half = block / 2;
        for start in (0..NTT_SIZE).step_by(block) {
            let mut factor = 1_i64;
            for offset in 0..half {
                let even = values[start + offset];
                let odd = values[start + offset + half] * factor % MODULUS;
                values[start + offset] = (even + odd) % MODULUS;
                values[start + offset + half] = (even - odd + MODULUS) % MODULUS;
                factor = factor * root % MODULUS;
            }
        }
        block <<= 1;
    }
    if inverse {
        let scale = mod_pow(NTT_SIZE as i64, MODULUS - 2);
        for value in values.iter_mut() { *value = *value * scale % MODULUS; }
    }
}

fn evaluate(coefficients: &[i64], x: i64) -> i64 {
    let mut value = 0_i64;
    for &coefficient in coefficients.iter().rev() { value = (value * x + coefficient) % MODULUS; }
    value
}

fn store_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn multipoint_evaluation_on_geometric_sequence(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 || input[1] < 1 || input[1] > MAX_M as i64 { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    let start = input[2];
    let ratio = input[3];
    if length != n + 4 || start < 0 || start >= MODULUS || ratio < 0 || ratio >= MODULUS { return -1; }
    for &coefficient in &input[4..] {
        if coefficient < 0 || coefficient >= MODULUS { return -1; }
    }
    let bytes = 8 * m;
    if output.is_null() || capacity < bytes { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, bytes) };
    if start == 0 {
        for i in 0..m { store_le(output, 8 * i, input[4]); }
        return bytes as i64;
    }
    if ratio == 0 {
        store_le(output, 0, evaluate(&input[4..4 + n], start));
        for i in 1..m { store_le(output, 8 * i, input[4]); }
        return bytes as i64;
    }

    let inverse_ratio = mod_pow(ratio, MODULUS - 2);
    let mut left = [0_i64; NTT_SIZE];
    let mut right = [0_i64; NTT_SIZE];
    let mut start_power = 1_i64;
    let mut inverse_chirp = 1_i64;
    let mut inverse_ratio_power = 1_i64;
    for degree in 0..n {
        left[n - 1 - degree] = input[4 + degree] * start_power % MODULUS * inverse_chirp % MODULUS;
        start_power = start_power * start % MODULUS;
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS;
    }
    let mut chirp = 1_i64;
    let mut ratio_power = 1_i64;
    for index in 0..n + m - 1 {
        right[index] = chirp;
        chirp = chirp * ratio_power % MODULUS;
        ratio_power = ratio_power * ratio % MODULUS;
    }
    ntt(&mut left, false);
    ntt(&mut right, false);
    for i in 0..NTT_SIZE { left[i] = left[i] * right[i] % MODULUS; }
    ntt(&mut left, true);
    inverse_chirp = 1;
    inverse_ratio_power = 1;
    for i in 0..m {
        store_le(output, 8 * i, left[n - 1 + i] * inverse_chirp % MODULUS);
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS;
    }
    bytes as i64
}
