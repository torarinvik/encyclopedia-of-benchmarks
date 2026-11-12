const MAX_LENGTH: usize = 64;
const MAX_NTT_SIZE: usize = 128;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_LENGTH + 1;
const MAX_RESULT_LENGTH: usize = 2 * MAX_LENGTH - 1;
const P0: i64 = 998_244_353;
const P1: i64 = 985_661_441;
const P2: i64 = 943_718_401;
const P3: i64 = 935_329_793;
const P4: i64 = 918_552_577;

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

fn transform(values: &mut [i64; MAX_NTT_SIZE], n: usize,
              modulus: i64, primitive_root: i64, inverse: bool) {
    let mut j = 0;
    for i in 1..n {
        let mut bit = n >> 1;
        while j & bit != 0 {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if i < j {
            values.swap(i, j);
        }
    }
    let mut stage = 2;
    while stage <= n {
        let mut root = power_mod(primitive_root, (modulus - 1) / stage as i64, modulus);
        if inverse {
            root = power_mod(root, modulus - 2, modulus);
        }
        for start in (0..n).step_by(stage) {
            let mut factor = 1;
            for offset in 0..stage / 2 {
                let left = values[start + offset];
                let right = values[start + offset + stage / 2] * factor % modulus;
                values[start + offset] = (left + right) % modulus;
                values[start + offset + stage / 2] = (left - right + modulus) % modulus;
                factor = factor * root % modulus;
            }
        }
        stage <<= 1;
    }
    if inverse {
        let scale = power_mod(n as i64, modulus - 2, modulus);
        for value in values.iter_mut().take(n) {
            *value = *value * scale % modulus;
        }
    }
}

unsafe fn convolution_residues(input: *const i64, n: usize, m: usize,
                               transform_length: usize, modulus: i64,
                               primitive_root: i64,
                               result: &mut [i64; MAX_RESULT_LENGTH]) {
    let mut a = [0i64; MAX_NTT_SIZE];
    let mut b = [0i64; MAX_NTT_SIZE];
    for i in 0..n {
        a[i] = (*input.add(2 + i) as u64 % modulus as u64) as i64;
    }
    for i in 0..m {
        b[i] = (*input.add(2 + n + i) as u64 % modulus as u64) as i64;
    }
    transform(&mut a, transform_length, modulus, primitive_root, false);
    transform(&mut b, transform_length, modulus, primitive_root, false);
    for i in 0..transform_length {
        a[i] = a[i] * b[i] % modulus;
    }
    transform(&mut a, transform_length, modulus, primitive_root, true);
    result[..n + m - 1].copy_from_slice(&a[..n + m - 1]);
}

fn positive_delta(value: i64, partial: i64, modulus: i64) -> i64 {
    let delta = value - partial;
    if delta < 0 { delta + modulus } else { delta }
}

unsafe fn store_u64_le(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 {
        *output.add(offset + byte) = (value >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn convolution_mod_2_64(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(1..=MAX_LENGTH as i64).contains(&n_value)
        || !(1..=MAX_LENGTH as i64).contains(&m_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + n + m {
        return -1;
    }
    let result_length = n + m - 1;
    let mut transform_length = 1;
    while transform_length < result_length {
        transform_length <<= 1;
    }
    let output_bytes = 8 * result_length;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut residues = [[0i64; MAX_RESULT_LENGTH]; 5];
    convolution_residues(input, n, m, transform_length, P0, 3, &mut residues[0]);
    convolution_residues(input, n, m, transform_length, P1, 3, &mut residues[1]);
    convolution_residues(input, n, m, transform_length, P2, 7, &mut residues[2]);
    convolution_residues(input, n, m, transform_length, P3, 3, &mut residues[3]);
    convolution_residues(input, n, m, transform_length, P4, 5, &mut residues[4]);

    let p01_p2 = (P0 % P2) * (P1 % P2) % P2;
    let p01_p3 = (P0 % P3) * (P1 % P3) % P3;
    let p01_p4 = (P0 % P4) * (P1 % P4) % P4;
    let p012_p3 = p01_p3 * (P2 % P3) % P3;
    let p012_p4 = p01_p4 * (P2 % P4) % P4;
    let p0123_p4 = p012_p4 * (P3 % P4) % P4;
    let inv0_p1 = power_mod(P0 % P1, P1 - 2, P1);
    let inv01_p2 = power_mod(p01_p2, P2 - 2, P2);
    let inv012_p3 = power_mod(p012_p3, P3 - 2, P3);
    let inv0123_p4 = power_mod(p0123_p4, P4 - 2, P4);

    for i in 0..result_length {
        let t0 = residues[0][i];
        let t1 = positive_delta(residues[1][i], t0 % P1, P1) * inv0_p1 % P1;
        let x01_p2 = (residues[0][i] % P2 + (P0 % P2) * t1) % P2;
        let t2 = positive_delta(residues[2][i], x01_p2, P2) * inv01_p2 % P2;
        let x012_p3 = (residues[0][i] % P3 + (P0 % P3) * t1 + p01_p3 * t2) % P3;
        let t3 = positive_delta(residues[3][i], x012_p3, P3) * inv012_p3 % P3;
        let x0123_p4 = (residues[0][i] % P4 + (P0 % P4) * t1
            + p01_p4 * t2 + p012_p4 * t3) % P4;
        let t4 = positive_delta(residues[4][i], x0123_p4, P4) * inv0123_p4 % P4;
        let value = (t0 as u64)
            .wrapping_add((P0 as u64).wrapping_mul(t1 as u64))
            .wrapping_add((P0 as u64).wrapping_mul(P1 as u64).wrapping_mul(t2 as u64))
            .wrapping_add((P0 as u64).wrapping_mul(P1 as u64).wrapping_mul(P2 as u64).wrapping_mul(t3 as u64))
            .wrapping_add((P0 as u64).wrapping_mul(P1 as u64).wrapping_mul(P2 as u64)
                .wrapping_mul(P3 as u64).wrapping_mul(t4 as u64));
        store_u64_le(output, 8 * i, value);
    }
    output_bytes as i64
}
