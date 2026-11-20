const MAX_H: usize = 32;
const MAX_W: usize = 32;
const MAX_Q: usize = 128;
const MAX_INPUT: usize = 1540;
const MAX_OUTPUT: usize = 1024;
const MODULUS: i64 = 1_000_000_007;
const ROW_BASE: i64 = 31;
const COL_BASE: i64 = 37;

fn execute(values: &[i64], capacity: usize, output_is_null: bool) -> (i64, [u8; MAX_OUTPUT]) {
    let mut staged = [0u8; MAX_OUTPUT];
    if values.len() < 3 || values.len() > MAX_INPUT { return (-1, staged); }
    let (h_value, w_value, q_value) = (values[0], values[1], values[2]);
    if h_value < 1 || h_value > MAX_H as i64 || w_value < 1 || w_value > MAX_W as i64
        || q_value < 1 || q_value > MAX_Q as i64 { return (-1, staged); }
    let (h, w, q) = (h_value as usize, w_value as usize, q_value as usize);
    if values.len() != 3 + h * w + 4 * q { return (-1, staged); }
    let query_offset = 3 + h * w;
    if values[3..query_offset].iter().any(|&x| !(0..=255).contains(&x)) { return (-1, staged); }
    for i in 0..q {
        let (r0, c0, r1, c1) = (values[query_offset + 4*i], values[query_offset + 4*i + 1],
            values[query_offset + 4*i + 2], values[query_offset + 4*i + 3]);
        if r0 < 0 || r0 > r1 || r1 > h_value || c0 < 0 || c0 > c1 || c1 > w_value { return (-1, staged); }
    }
    let required = 8 * q;
    if output_is_null || capacity < required { return (-2, staged); }

    let mut row_power = [1i64; MAX_H + 1];
    let mut col_power = [1i64; MAX_W + 1];
    for i in 1..=h { row_power[i] = row_power[i - 1] * ROW_BASE % MODULUS; }
    for j in 1..=w { col_power[j] = col_power[j - 1] * COL_BASE % MODULUS; }
    let mut prefix = [[0i64; MAX_W + 1]; MAX_H + 1];
    for r in 1..=h {
        let mut row_hash = 0i64;
        for c in 1..=w {
            row_hash = (row_hash * COL_BASE + values[3 + (r - 1) * w + c - 1]) % MODULUS;
            prefix[r][c] = (prefix[r - 1][c] * ROW_BASE + row_hash) % MODULUS;
        }
    }
    for i in 0..q {
        let r0 = values[query_offset + 4*i] as usize;
        let c0 = values[query_offset + 4*i + 1] as usize;
        let r1 = values[query_offset + 4*i + 2] as usize;
        let c1 = values[query_offset + 4*i + 3] as usize;
        let (rh, cw) = (r1 - r0, c1 - c0);
        let mut hash = prefix[r1][c1]
            - prefix[r0][c1] * row_power[rh] % MODULUS
            - prefix[r1][c0] * col_power[cw] % MODULUS
            + prefix[r0][c0] * row_power[rh] % MODULUS * col_power[cw] % MODULUS;
        hash %= MODULUS;
        if hash < 0 { hash += MODULUS; }
        staged[8*i..8*i+8].copy_from_slice(&hash.to_le_bytes());
    }
    (required as i64, staged)
}

#[no_mangle]
pub unsafe extern "C" fn rolling_hash_2d_rectangle_query(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (result, staged) = execute(values, capacity, output.is_null());
    if result > 0 {
        std::slice::from_raw_parts_mut(output, result as usize)
            .copy_from_slice(&staged[..result as usize]);
    }
    result
}
