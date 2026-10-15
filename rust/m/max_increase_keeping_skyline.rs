/// Return the total allowable increase while preserving row and column skylines.
#[no_mangle]
pub extern "C" fn max_increase_keeping_skyline(values: *const i64, length: usize) -> i64 {
    const MAX_GRID_SIZE: usize = 50;
    if values.is_null() || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 2 || values[0] > MAX_GRID_SIZE as i64 { return -1; }
    let size = values[0] as usize;
    if length != 1 + size * size { return -1; }

    let mut row_max = [0i64; MAX_GRID_SIZE];
    let mut column_max = [0i64; MAX_GRID_SIZE];
    for row in 0..size {
        for column in 0..size {
            let height = values[1 + row * size + column];
            if !(0..=100).contains(&height) { return -1; }
            row_max[row] = row_max[row].max(height);
            column_max[column] = column_max[column].max(height);
        }
    }

    let mut total = 0i64;
    for row in 0..size {
        for column in 0..size {
            let height = values[1 + row * size + column];
            total += row_max[row].min(column_max[column]) - height;
        }
    }
    total
}
