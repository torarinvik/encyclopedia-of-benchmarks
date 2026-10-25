const MAX_SIDE: usize = 8;
const MAX_PASSES: usize = 4;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_INPUT_LENGTH: usize = 2 + MAX_CELLS;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

/// Clean-room bounded profile of TSVC s2111; see package README.
#[no_mangle]
pub unsafe extern "C" fn tsvc_s2111_wavefront_add_recurrence(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let side_raw = values[0];
    let passes_raw = values[1];
    if !(2..=MAX_SIDE as i64).contains(&side_raw) || !(1..=MAX_PASSES as i64).contains(&passes_raw) { return -1; }
    let side = side_raw as usize;
    let cells = side * side;
    if length != 2 + cells { return -1; }

    let mut matrix = [0i64; MAX_CELLS];
    for cell in 0..cells {
        let value = values[2 + cell];
        if !(-8..=8).contains(&value) { return -1; }
        matrix[cell] = value;
    }
    if output.is_null() || output_capacity < 8 * cells { return -2; }

    for _ in 0..passes_raw as usize {
        for row in 1..side {
            for col in 1..side {
                matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col];
            }
        }
    }
    for cell in 0..cells { store_i64_le(output, 8 * cell, matrix[cell]); }
    cells as i64
}
