//! Bounded normalized Padé coefficient construction over F_998244353.
const MODULUS: i64 = 998_244_353;
const MAX_INPUT_LENGTH: usize = 12;

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn pade_approximant_series_coefficients(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(5..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let p_value = values[0];
    let q_value = values[1];
    if q_value < 1 || p_value < q_value || p_value > 4 || q_value > 4
        || length != (p_value + q_value + 3) as usize { return -1; }
    let p = p_value as usize;
    let q = q_value as usize;
    let mut coefficients = [0u32; 9];
    for index in 0..=p + q {
        let coefficient = values[index + 2];
        if !(0..MODULUS).contains(&coefficient) { return -1; }
        coefficients[index] = coefficient as u32;
    }
    let required = 8 * (p + q + 4);
    if output.is_null() || capacity < required { return -2; }

    let mut matrix = [[0u32; 5]; 4];
    for row in 0..q {
        let m = p + 1 + row;
        for col in 0..q { matrix[row][col] = coefficients[m - col - 1]; }
        matrix[row][q] = ((MODULUS - coefficients[m] as i64) % MODULUS) as u32;
    }
    for col in 0..q {
        let pivot = (col..q).find(|&row| matrix[row][col] != 0);
        let Some(pivot) = pivot else { return -3; };
        if pivot != col { matrix.swap(pivot, col); }
        let inverse = mod_pow(matrix[col][col] as i64, MODULUS - 2);
        for j in col..=q {
            matrix[col][j] = (matrix[col][j] as i64 * inverse % MODULUS) as u32;
        }
        for row in 0..q {
            if row == col { continue; }
            let factor = matrix[row][col] as i64;
            for j in col..=q {
                let product = factor * matrix[col][j] as i64 % MODULUS;
                let mut difference = matrix[row][j] as i64 - product;
                if difference < 0 { difference += MODULUS; }
                matrix[row][j] = difference as u32;
            }
        }
    }

    let bytes = unsafe { std::slice::from_raw_parts_mut(output, required) };
    store_i64_le(bytes, 0, p_value);
    store_i64_le(bytes, 8, q_value);
    let mut offset = 16;
    for m in 0..=p {
        let mut value = coefficients[m] as u64;
        for j in 1..=std::cmp::min(m, q) {
            value = (value + coefficients[m - j] as u64 * matrix[j - 1][q] as u64) % MODULUS as u64;
        }
        store_i64_le(bytes, offset, value as i64);
        offset += 8;
    }
    store_i64_le(bytes, offset, 1);
    offset += 8;
    for j in 0..q {
        store_i64_le(bytes, offset, matrix[j][q] as i64);
        offset += 8;
    }
    required as i64
}
