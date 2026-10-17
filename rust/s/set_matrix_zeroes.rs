const MAX_INPUT_LENGTH: usize = 67;
const MAX_CELLS: usize = 64;
const MIN_CELL: i64 = -1_000_000;
const MAX_CELL: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn set_matrix_zeroes(input: *const i64, length: usize,
                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0];
    let columns_value = values[1];
    if !(1..=8).contains(&rows_value) || !(1..=8).contains(&columns_value) { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != 2 + cells { return -1; }

    let mut matrix = [0_i64; MAX_CELLS];
    for index in 0..cells {
        let value = values[2 + index];
        if !(MIN_CELL..=MAX_CELL).contains(&value) { return -1; }
        matrix[index] = value;
    }

    let bytes = cells * 8;
    if output.is_null() || capacity < bytes { return -2; }

    let mut first_column_zero = false;
    for row in 0..rows {
        if matrix[row * columns] == 0 { first_column_zero = true; }
        for column in 1..columns {
            if matrix[row * columns + column] == 0 {
                matrix[row * columns] = 0;
                matrix[column] = 0;
            }
        }
    }
    for row in 1..rows {
        for column in 1..columns {
            if matrix[row * columns] == 0 || matrix[column] == 0 {
                matrix[row * columns + column] = 0;
            }
        }
    }
    if matrix[0] == 0 {
        for column in 0..columns { matrix[column] = 0; }
    }
    if first_column_zero {
        for row in 0..rows { matrix[row * columns] = 0; }
    }

    let destination = std::slice::from_raw_parts_mut(output, bytes);
    for index in 0..cells {
        destination[index * 8..index * 8 + 8].copy_from_slice(&matrix[index].to_le_bytes());
    }
    bytes as i64
}
