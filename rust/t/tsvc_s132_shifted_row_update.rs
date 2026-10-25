const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_N;
const MAX_VALUE: i64 = 1_000_000;

fn bounded_value(value: i64) -> bool {
    (-MAX_VALUE..=MAX_VALUE).contains(&value)
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s132_shifted_row_update(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 8 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 2 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 2 + 3 * n { return -1; }

    let row_start = 1;
    let target_start = row_start + n;
    let b_start = target_start + n;
    let c1_index = b_start + n;
    let mut target = [0i64; MAX_N];
    for i in 0..n {
        target[i] = values[target_start + i];
        if !bounded_value(values[row_start + i]) || !bounded_value(target[i]) ||
            !bounded_value(values[b_start + i]) { return -1; }
    }
    let c1 = values[c1_index];
    if !bounded_value(c1) { return -1; }
    if output.is_null() || output_capacity < 8 * n { return -2; }

    for i in 1..n {
        target[i] = values[row_start + i - 1] + values[b_start + i] * c1;
    }
    for i in 0..n { store_i64_le(output, 8 * i, target[i]); }
    n as i64
}
