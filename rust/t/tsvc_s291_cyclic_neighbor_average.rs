const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + MAX_N;
const MAX_VALUE: i64 = 1_000_000;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s291_cyclic_neighbor_average(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 2 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + n { return -1; }
    if values[1..].iter().any(|&value| !(-MAX_VALUE..=MAX_VALUE).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < 8 * n { return -2; }

    for i in 0..n {
        let previous = if i == 0 { n - 1 } else { i - 1 };
        store_i64_le(output, 8 * i, values[i + 1] + values[previous + 1]);
    }
    n as i64
}
