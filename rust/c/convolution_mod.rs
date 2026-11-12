const MODULUS: i64 = 998_244_353;
const MAX_LENGTH: usize = 256;
const MAX_NTT_SIZE: usize = 512;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_LENGTH;

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 {
            result = result * base % MODULUS;
        }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn transform(values: &mut [i64; MAX_NTT_SIZE], n: usize, inverse: bool) {
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
        let mut root = power_mod(3, (MODULUS - 1) / stage as i64);
        if inverse {
            root = power_mod(root, MODULUS - 2);
        }
        let mut start = 0;
        while start < n {
            let mut factor = 1;
            for offset in 0..stage / 2 {
                let left = values[start + offset];
                let right = values[start + offset + stage / 2] * factor % MODULUS;
                values[start + offset] = (left + right) % MODULUS;
                values[start + offset + stage / 2] = (left - right + MODULUS) % MODULUS;
                factor = factor * root % MODULUS;
            }
            start += stage;
        }
        stage *= 2;
    }
    if inverse {
        let scale = power_mod(n as i64, MODULUS - 2);
        for value in &mut values[..n] {
            *value = *value * scale % MODULUS;
        }
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn convolution_mod(
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
    for i in 0..n + m {
        let coefficient = *input.add(2 + i);
        if !(0..MODULUS).contains(&coefficient) {
            return -1;
        }
    }

    let result_length = n + m - 1;
    let mut transform_length = 1;
    while transform_length < result_length {
        transform_length *= 2;
    }
    let output_bytes = 8 * result_length;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut a = [0i64; MAX_NTT_SIZE];
    let mut b = [0i64; MAX_NTT_SIZE];
    for i in 0..n {
        a[i] = *input.add(2 + i);
    }
    for i in 0..m {
        b[i] = *input.add(2 + n + i);
    }
    transform(&mut a, transform_length, false);
    transform(&mut b, transform_length, false);
    for i in 0..transform_length {
        a[i] = a[i] * b[i] % MODULUS;
    }
    transform(&mut a, transform_length, true);
    for i in 0..result_length {
        store_i64_le(output, 8 * i, a[i]);
    }
    output_bytes as i64
}
