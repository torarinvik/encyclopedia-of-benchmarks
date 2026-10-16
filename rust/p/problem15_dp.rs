#[no_mangle]
pub extern "C" fn problem15_dp(grid_size: i64) -> i64 {
    if !(0..=20).contains(&grid_size) {
        return -1;
    }
    let size = grid_size as usize;
    let mut counts = [[1_i64; 21]; 21];
    for row in 1..=size {
        for column in 1..=size {
            counts[row][column] = counts[row - 1][column] + counts[row][column - 1];
        }
    }
    counts[size][size]
}
