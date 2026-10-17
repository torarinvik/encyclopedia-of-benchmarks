const MAX_CELLS: usize = 16 * 16;
const MAX_INPUT_LENGTH: usize = 259;

#[no_mangle]
pub unsafe extern "C" fn spiral_print(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=16).contains(&values[0]) || !(2..=16).contains(&values[1]) { return -1; }
    let rows = values[0] as usize;
    let columns = values[1] as usize;
    let cell_count = rows * columns;
    if length != 2 + cell_count { return -1; }
    let mut matrix = [0_i32; MAX_CELLS];
    for index in 0..cell_count {
        let value = values[2 + index];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        matrix[index] = value as i32;
    }
    let required = 8 * cell_count;
    if output.is_null() || capacity < required { return -2; }

    let mut order = [0_i32; MAX_CELLS];
    let mut written = 0usize;
    let (mut top, mut bottom, mut left, mut right) = (0isize, rows as isize - 1, 0isize, columns as isize - 1);
    while top <= bottom && left <= right {
        for column in left..=right { order[written] = matrix[top as usize * columns + column as usize]; written += 1; }
        top += 1;
        for row in top..=bottom { order[written] = matrix[row as usize * columns + right as usize]; written += 1; }
        right -= 1;
        if top <= bottom && left <= right {
            for column in (left..=right).rev() { order[written] = matrix[bottom as usize * columns + column as usize]; written += 1; }
            bottom -= 1;
        }
        if top <= bottom && left <= right {
            for row in (top..=bottom).rev() { order[written] = matrix[row as usize * columns + left as usize]; written += 1; }
            left += 1;
        }
    }
    for index in 0..written {
        let bytes = i64::from(order[index]).to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    required as i64
}
