const MODULUS: i64 = 998_244_353;
const MAX_WORDS: usize = 11;
const TABLE_COLUMNS: usize = 9;

fn normalize(value: i64) -> i64 {
    let reduced = value % MODULUS;
    if reduced < 0 { reduced + MODULUS } else { reduced }
}

fn multiply(left: i64, right: i64) -> i64 { (left * right) % MODULUS }

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = multiply(result, base); }
        base = multiply(base, base);
        exponent >>= 1;
    }
    result
}

fn store_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn stieltjes_quotient_difference_transform(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_WORDS { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let n0 = values[0];
    if !(2..=9).contains(&n0) || input_length != n0 as usize + 1 { return -1; }
    let n = n0 as usize;
    if values[1..].iter().any(|&value| value <= 0 || value >= MODULUS) { return -1; }

    let mut q = [[0_i64; TABLE_COLUMNS]; 5];
    let mut e = [[0_i64; TABLE_COLUMNS]; 5];
    for k in 0..n - 1 {
        q[1][k] = multiply(values[k + 2], power(values[k + 1], MODULUS - 2));
    }
    for j in 1..=4 {
        let last_e = n as i32 - 2 * j as i32 - 1;
        if last_e < 0 { break; }
        for k in 0..=last_e as usize {
            e[j][k] = normalize(e[j - 1][k + 1] + q[j][k + 1] - q[j][k]);
        }
        let last_q = n as i32 - 2 * j as i32 - 2;
        if last_q >= 0 {
            for k in 0..=last_q as usize {
                let pivot = e[j][k];
                if pivot == 0 { return -1; }
                let product = multiply(q[j][k + 1], e[j][k + 1]);
                q[j + 1][k] = multiply(product, power(pivot, MODULUS - 2));
            }
        }
    }

    let required = 8 * (n + 1);
    if output.is_null() || output_capacity < required { return -2; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, required) };
    store_i64(destination, 0, n as i64);
    for index in 1..n {
        let row = (index + 1) / 2;
        let value = if index & 1 == 1 { q[row][0] } else { e[index / 2][0] };
        store_i64(destination, 8 * index, value);
    }
    required as i64
}
