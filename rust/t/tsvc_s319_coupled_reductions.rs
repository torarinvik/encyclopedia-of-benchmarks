const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_N;
const MAX_VALUE: i64 = 2;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s319_coupled_reductions(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + 3 * n { return -1; }

    let c_start = 1;
    let d_start = c_start + n;
    let e_start = d_start + n;
    for i in 0..n {
        if !(-MAX_VALUE..=MAX_VALUE).contains(&values[c_start + i]) ||
            !(-MAX_VALUE..=MAX_VALUE).contains(&values[d_start + i]) ||
            !(-MAX_VALUE..=MAX_VALUE).contains(&values[e_start + i]) { return -1; }
    }
    let value_count = 2 * n + 1;
    if output.is_null() || output_capacity < 8 * value_count { return -2; }

    let mut total = 0i64;
    for i in 0..n {
        let a_value = values[c_start + i] + values[d_start + i];
        let b_value = values[c_start + i] + values[e_start + i];
        store_i64_le(output, 8 * i, a_value);
        store_i64_le(output, 8 * (n + i), b_value);
        total += a_value;
        total += b_value;
    }
    store_i64_le(output, 8 * (2 * n), total);
    value_count as i64
}
