const MAX_N: usize = 8;
const MAX_CELLS: usize = MAX_N * MAX_N;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_CELLS;
const MAX_VALUE: i64 = 100;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s2101_diagonal_matrix_fma(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    let cells = n * n;
    if length != 1 + 3 * cells { return -1; }
    if values[1..].iter().any(|&value| !(-MAX_VALUE..=MAX_VALUE).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < 8 * cells { return -2; }

    for cell in 0..cells {
        store_i64_le(output, 8 * cell, values[cell + 1]);
    }
    for i in 0..n {
        let diagonal = i * n + i;
        let value = values[1 + diagonal]
            + values[1 + cells + diagonal] * values[1 + 2 * cells + diagonal];
        store_i64_le(output, 8 * diagonal, value);
    }
    cells as i64
}
