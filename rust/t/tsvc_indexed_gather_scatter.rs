const MAX_N: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + 5 * MAX_N;
const MAX_OPERAND: i64 = 1_000_000;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

fn bounded_operand(value: i64) -> bool {
    (-MAX_OPERAND..=MAX_OPERAND).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_indexed_gather_scatter(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mode = values[0];
    let n_raw = values[1];
    if (mode != 491 && mode != 4113) || n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    let arrays_per_index = if mode == 491 { 5 } else { 4 };
    if length != 2 + arrays_per_index * n { return -1; }

    let index_start = 2;
    let a_start = index_start + n;
    let b_start = a_start + n;
    let c_start = b_start + n;
    let d_start = c_start + n;
    let mut state = [0i64; MAX_N];
    for i in 0..n {
        let index = values[index_start + i];
        if index < 0 || index >= n_raw { return -1; }
        state[i] = values[a_start + i];
        if !bounded_operand(values[b_start + i]) || !bounded_operand(values[c_start + i]) { return -1; }
        if mode == 491 && !bounded_operand(values[d_start + i]) { return -1; }
    }
    if output.is_null() || output_capacity < 8 * n { return -2; }

    for i in 0..n {
        let index = values[index_start + i] as usize;
        if mode == 491 {
            state[index] = values[b_start + i] + values[c_start + i] * values[d_start + i];
        } else {
            state[index] = values[b_start + index] + values[c_start + i];
        }
    }
    for i in 0..n { store_i64_le(output, 8 * i, state[i]); }
    n as i64
}
