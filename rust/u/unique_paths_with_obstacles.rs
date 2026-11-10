/// Count right/down paths through a packed obstacle grid.
const MAX_ROWS: i64 = 20;
const MAX_COLUMNS: i64 = 20;

#[no_mangle]
pub unsafe extern "C" fn unique_paths_with_obstacles(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let rows_value = *input;
    let columns_value = *input.add(1);
    if rows_value < 1 || rows_value > MAX_ROWS ||
        columns_value < 1 || columns_value > MAX_COLUMNS { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    if length != 2 + rows * columns { return -1; }

    let mut paths = [0_u64; MAX_COLUMNS as usize];
    paths[0] = 1;
    let mut cells_seen = 0u64;
    let mut left = 0u64;
    let mut index = 2;
    while index < length {
        left = 0;
        for column in 0..columns {
            let obstacle = *input.add(index) as u64;
            cells_seen |= obstacle;
            left = if obstacle == 0 { left + paths[column] } else { 0 };
            paths[column] = left;
            index += 1;
        }
    }
    if cells_seen > 1 { return -1; }
    left as i64
}
