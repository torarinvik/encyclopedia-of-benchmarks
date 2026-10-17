const MAX_DIMENSION: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 259;
const I32_MIN: i64 = i32::MIN as i64;
const I32_MAX: i64 = i32::MAX as i64;

fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn mirror_of_matrix(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_rows = input[0];
    let raw_columns = input[1];
    if raw_rows < 1 || raw_rows > MAX_DIMENSION as i64 ||
        raw_columns < 1 || raw_columns > MAX_DIMENSION as i64 { return -1; }
    let rows = raw_rows as usize;
    let columns = raw_columns as usize;
    let cell_count = rows * columns;
    if length != 2 + cell_count { return -1; }
    let cells = &input[2..];
    if cells.iter().any(|&cell| cell < I32_MIN || cell > I32_MAX) { return -1; }

    let byte_count = 4 * cell_count;
    if output.is_null() || capacity < byte_count { return -2; }
    for row in 0..rows {
        for column in 0..columns {
            let source_index = 2 + row * columns + (columns - 1 - column);
            store_i32_le(output, 4 * (row * columns + column), input[source_index] as i32);
        }
    }
    byte_count as i64
}
