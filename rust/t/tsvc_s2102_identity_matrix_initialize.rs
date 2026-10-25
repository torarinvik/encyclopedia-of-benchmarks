const MAX_SIDE: usize = 8;
const MAX_PASSES: usize = 8;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

/// Clean-room bounded profile of TSVC s2102; see package README.
#[no_mangle]
pub unsafe extern "C" fn tsvc_s2102_identity_matrix_initialize(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let side_raw = values[0];
    let passes_raw = values[1];
    if !(1..=MAX_SIDE as i64).contains(&side_raw) || !(1..=MAX_PASSES as i64).contains(&passes_raw) { return -1; }
    let side = side_raw as usize;
    let cells = side * side;
    if output.is_null() || output_capacity < 8 * cells { return -2; }

    let mut matrix = [0i64; MAX_CELLS];
    for _ in 0..passes_raw as usize {
        for col in 0..side {
            for row in 0..side { matrix[row * side + col] = 0; }
            matrix[col * side + col] = 1;
        }
    }
    for cell in 0..cells { store_i64_le(output, 8 * cell, matrix[cell]); }
    cells as i64
}
