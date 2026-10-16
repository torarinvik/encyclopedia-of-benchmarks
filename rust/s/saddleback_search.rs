/// Top-right staircase search for a strictly increasing integer matrix.
#[no_mangle]
pub unsafe extern "C" fn saddleback_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -1; }
    let rows_value = *values;
    let columns_value = *values.add(1);
    let target = *values.add(2);
    if rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32 {
        return -1;
    }
    if target < -2147483648 || target > 2147483647 { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != 3 + cells { return -1; }
    let matrix = values.add(3);
    for index in 0..cells {
        let value = *matrix.add(index);
        if value < -2147483648 || value > 2147483647 { return -1; }
    }

    let mut row = 0;
    let mut column = columns - 1;
    while row < rows {
        let value = *matrix.add(row * columns + column);
        if value == target { return (row * columns + column + 1) as i64; }
        if value < target {
            row += 1;
        } else if column == 0 {
            break;
        } else {
            column -= 1;
        }
    }
    0
}
