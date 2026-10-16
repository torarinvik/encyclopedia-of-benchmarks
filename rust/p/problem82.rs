/// Minimum cost from any left-column cell to any right-column cell, moving up, down, or right.
#[no_mangle]
pub extern "C" fn problem82(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let row_value = input[0];
    let column_value = input[1];
    if !(1..=80).contains(&row_value) || !(1..=80).contains(&column_value) {
        return -1;
    }
    let rows = row_value as usize;
    let columns = column_value as usize;
    if length != 2 + rows * columns {
        return -1;
    }
    if input[2..].iter().any(|&value| !(0..=9999).contains(&value)) {
        return -1;
    }

    let mut costs = [0i64; 80];
    for row in 0..rows {
        costs[row] = input[2 + row * columns];
    }
    for column in 1..columns {
        let offset = 2 + column;
        for row in 0..rows {
            costs[row] += input[offset + row * columns];
        }
        for row in 1..rows {
            let from_above = costs[row - 1] + input[offset + row * columns];
            costs[row] = costs[row].min(from_above);
        }
        for row in (0..rows.saturating_sub(1)).rev() {
            let from_below = costs[row + 1] + input[offset + row * columns];
            costs[row] = costs[row].min(from_below);
        }
    }
    *costs[..rows].iter().min().unwrap()
}
