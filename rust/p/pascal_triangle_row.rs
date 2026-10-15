/// Compute one row of Pascal's triangle using in-place dynamic programming.
#[no_mangle]
pub extern "C" fn pascal_triangle_row(row_index: i64, output: *mut u8,
                                     output_capacity: usize) -> i64 {
    if !(0..=33).contains(&row_index) { return -1; }
    let count = row_index as usize + 1;
    let required = count * 4;
    if output.is_null() || output_capacity < required { return -2; }

    let mut coefficients = [1u32; 34];
    for row in 2..=row_index as usize {
        for column in (1..row).rev() {
            coefficients[column] += coefficients[column - 1];
        }
    }

    let mut position = 0usize;
    for coefficient in coefficients.iter().take(count) {
        for byte in 0..4 {
            unsafe { output.add(position).write((coefficient >> (byte * 8)) as u8); }
            position += 1;
        }
    }
    position as i64
}
