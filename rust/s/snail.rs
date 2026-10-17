const MAX_CELLS: usize = 16 * 16;
const MAX_INPUT_LENGTH: usize = 259;

fn write_i32_le(output: &mut [u8], index: usize, value: i32) {
    let offset = index * 4;
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn snail(
    values: *const i32,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let rows_value = input[0];
    let columns_value = input[1];
    if !(0..=16).contains(&rows_value) || !(0..=16).contains(&columns_value) {
        return -1;
    }
    if rows_value == 0 && columns_value != 0 {
        return -1;
    }
    if columns_value == 1 && rows_value != 1 {
        return -1;
    }

    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cell_count = rows * columns;
    if length != 2 + cell_count {
        return -1;
    }

    let required_bytes = cell_count * 4;
    if output.is_null() || output_capacity < required_bytes {
        return -2;
    }
    if cell_count == 0 {
        return 0;
    }

    let mut matrix = [0_i32; MAX_CELLS];
    matrix[..cell_count].copy_from_slice(&input[2..]);
    let output = std::slice::from_raw_parts_mut(output, required_bytes);

    let (mut top, mut bottom) = (0_i32, rows as i32 - 1);
    let (mut left, mut right) = (0_i32, columns as i32 - 1);
    let mut written = 0usize;
    while top <= bottom && left <= right {
        for column in left..=right {
            let index = top as usize * columns + column as usize;
            write_i32_le(output, written, matrix[index]);
            written += 1;
        }
        top += 1;

        for row in top..=bottom {
            let index = row as usize * columns + right as usize;
            write_i32_le(output, written, matrix[index]);
            written += 1;
        }
        right -= 1;

        if top <= bottom && left <= right {
            for column in (left..=right).rev() {
                let index = bottom as usize * columns + column as usize;
                write_i32_le(output, written, matrix[index]);
                written += 1;
            }
            bottom -= 1;
        }

        if top <= bottom && left <= right {
            for row in (top..=bottom).rev() {
                let index = row as usize * columns + left as usize;
                write_i32_le(output, written, matrix[index]);
                written += 1;
            }
            left += 1;
        }
    }
    required_bytes as i64
}
