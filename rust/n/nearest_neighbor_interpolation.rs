const MAX_INPUT_LENGTH: usize = 2 + 16 * 16;

#[no_mangle]
pub unsafe extern "C" fn nearest_neighbor_interpolation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let rows_value = input[0];
    let columns_value = input[1];
    if !(1..=16).contains(&rows_value) || !(1..=16).contains(&columns_value) { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let input_cells = rows * columns;
    if length != 2 + input_cells || input[2..].iter().any(|&pixel| !(0..=255).contains(&pixel)) {
        return -1;
    }

    let output_rows = 3 * rows / 2;
    let output_columns = 3 * columns / 2;
    let output_bytes = output_rows * output_columns;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output = std::slice::from_raw_parts_mut(output, output_bytes);
    for y in 0..output_rows {
        let source_y = (4 * (y + 1) + 3) / 6 - 1;
        for x in 0..output_columns {
            let source_x = (4 * (x + 1) + 3) / 6 - 1;
            output[y * output_columns + x] = input[2 + source_y * columns + source_x] as u8;
        }
    }
    output_bytes as i64
}
