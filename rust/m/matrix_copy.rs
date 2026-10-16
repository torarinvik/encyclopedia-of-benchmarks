const MAX_DIMENSION: usize = 32;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn matrix_copy(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 2 + MAX_DIMENSION * MAX_DIMENSION { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let (rows_value, columns_value) = (input[0], input[1]);
    if rows_value < 0 || rows_value > MAX_DIMENSION as i64 ||
       columns_value < 0 || columns_value > MAX_DIMENSION as i64 { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let element_count = rows * columns;
    if length != 2 + element_count { return -1; }
    if input[2..].iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) { return -1; }
    let (result_rows, result_columns) = if rows == 0 || columns == 0 { (0, 0) } else { (rows, columns) };
    let result_count = result_rows * result_columns;
    let output_bytes = (2 + result_count) * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    store_i64_le(output, 0, result_rows as i64);
    store_i64_le(output, 8, result_columns as i64);
    for index in 0..result_count { store_i64_le(output, 16 + index * 8, input[2 + index]); }
    output_bytes as i64
}
