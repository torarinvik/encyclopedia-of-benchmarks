const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N;
const MAX_VALUE: i64 = 2;

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
pub unsafe extern "C" fn tsvc_s452_index_weighted_vector_map(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + 2 * n { return -1; }

    let b_start = 1;
    let c_start = b_start + n;
    for i in 0..n {
        if !bounded_value(values[b_start + i]) || !bounded_value(values[c_start + i]) { return -1; }
    }
    if output.is_null() || output_capacity < 8 * n { return -2; }

    for i in 0..n {
        let index_weight = (i + 1) as i64;
        let value = values[b_start + i] + values[c_start + i] * index_weight;
        store_i64_le(output, 8 * i, value);
    }
    n as i64
}
