/// Minimum cost from the top-left to bottom-right, moving only right or down.
#[no_mangle]
pub extern "C" fn minimum_path_sum(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 66 {
        return i64::MIN;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let row_value = input[0];
    let column_value = input[1];
    if !(1..=8).contains(&row_value) || !(1..=8).contains(&column_value) {
        return i64::MIN;
    }
    let rows = row_value as usize;
    let columns = column_value as usize;
    if length != 2 + rows * columns {
        return i64::MIN;
    }
    let mut costs = [0i64; 8];
    for row in 0..rows {
        for column in 0..columns {
            let cell = input[2 + row * columns + column];
            if !(0..=1000).contains(&cell) {
                return i64::MIN;
            }
            if row == 0 && column == 0 {
                costs[column] = cell;
            } else if row == 0 {
                costs[column] = costs[column - 1] + cell;
            } else if column == 0 {
                costs[column] += cell;
            } else {
                costs[column] = costs[column].min(costs[column - 1]) + cell;
            }
        }
    }
    costs[columns - 1]
}
