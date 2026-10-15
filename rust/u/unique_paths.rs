/// Count right-and-down paths with one row of dynamic programming.
#[no_mangle]
pub extern "C" fn unique_paths(rows: u64, columns: u64) -> i64 {
    if rows == 0 || columns == 0 || rows > 34 || columns > 34 { return -1; }
    let width = rows.min(columns);
    let height = rows.max(columns);
    let mut paths = [0i64; 34];
    for column in 0..width as usize { paths[column] = 1; }
    for _row in 1..height {
        for column in 1..width as usize {
            paths[column] += paths[column - 1];
        }
    }
    paths[(width - 1) as usize]
}
