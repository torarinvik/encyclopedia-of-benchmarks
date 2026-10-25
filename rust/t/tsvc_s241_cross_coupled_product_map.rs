const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_N;
const MAX_VALUE: i64 = 2;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s241_cross_coupled_product_map(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 9 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 2 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + 4 * n { return -1; }

    let a_start = 1;
    let b_start = a_start + n;
    let c_start = b_start + n;
    let d_start = c_start + n;
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[a_start + i];
        b[i] = values[b_start + i];
        if a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
            b[i] < -MAX_VALUE || b[i] > MAX_VALUE ||
            values[c_start + i] < -MAX_VALUE || values[c_start + i] > MAX_VALUE ||
            values[d_start + i] < -MAX_VALUE || values[d_start + i] > MAX_VALUE { return -1; }
    }
    if output.is_null() || output_capacity < 16 * n { return -2; }

    for i in 0..n - 1 {
        let next_a = a[i + 1];
        a[i] = b[i] * values[c_start + i] * values[d_start + i];
        b[i] = a[i] * next_a * values[d_start + i];
    }
    for i in 0..n {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
    }
    (2 * n) as i64
}
