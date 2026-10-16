const MAX_N: i64 = 8;
fn count_from(n: usize, column: usize, rows: &mut [bool; 8], down: &mut [bool; 16], up: &mut [bool; 16]) -> i64 {
    if column == n { return 1; }
    let mut count = 0;
    for row in 0..n {
        let d = row + n - 1 - column;
        let u = row + column;
        if !rows[row] && !down[d] && !up[u] {
            rows[row] = true; down[d] = true; up[u] = true;
            count += count_from(n, column + 1, rows, down, up);
            rows[row] = false; down[d] = false; up[u] = false;
        }
    }
    count
}
#[no_mangle]
pub unsafe extern "C" fn n_queens_solution_count(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_N { return -1; }
    let n = input[0] as usize;
    let mut rows = [false; 8];
    let mut down = [false; 16];
    let mut up = [false; 16];
    count_from(n, 0, &mut rows, &mut down, &mut up)
}
