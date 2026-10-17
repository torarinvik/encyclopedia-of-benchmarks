const MAX_DIMENSION: usize = 63;
const MAX_INPUT_VALUES: usize = 2 + MAX_DIMENSION * MAX_DIMENSION;

unsafe fn write_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = (value as i32).to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        *output.add(offset + index) = *byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn search_in_arow_and_col_wise_sorted_matrix(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let target = values[1];
    if !(1..=MAX_DIMENSION as i64).contains(&n_value) ||
        target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    let n = n_value as usize;
    if length != 2 + n * n { return -1; }

    let mut target_count = 0usize;
    for row in 0..n {
        for column in 0..n {
            let index = row * n + column;
            let value = values[2 + index];
            if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
            if column > 0 && value < values[2 + index - 1] { return -1; }
            if row > 0 && value < values[2 + index - n] { return -1; }
            if value == target {
                target_count += 1;
                if target_count > 1 { return -1; }
            }
        }
    }

    let mut row = 0usize;
    let mut column = n as isize - 1;
    let mut result_row = -1i64;
    let mut result_column = -1i64;
    let mut found = 0i64;
    while row < n && column >= 0 {
        let value = values[2 + row * n + column as usize];
        if value == target {
            result_row = row as i64;
            result_column = column as i64;
            found = 1;
            break;
        }
        if target > value { row += 1; } else { column -= 1; }
    }

    if output.is_null() || capacity < 8 { return -2; }
    let mut buffer = [0u8; 8];
    write_i32_le(buffer.as_mut_ptr(), 0, result_row);
    write_i32_le(buffer.as_mut_ptr(), 4, result_column);
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, 8);
    found
}
