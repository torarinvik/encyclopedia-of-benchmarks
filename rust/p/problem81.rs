const MAX_DIMENSION: usize = 80;
const MAX_CELL_VALUE: i64 = 9999;

#[no_mangle]
pub extern "C" fn problem81(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let dimension_value = values[0];
    if dimension_value < 1 || dimension_value > MAX_DIMENSION as i64 { return -1; }
    let dimension = dimension_value as usize;
    if length != 1 + dimension * dimension { return -1; }
    if values[1..].iter().any(|&value| value < 0 || value > MAX_CELL_VALUE) { return -1; }

    let mut costs = [0i64; MAX_DIMENSION];
    costs[0] = values[1];
    for column in 1..dimension {
        costs[column] = costs[column - 1] + values[1 + column];
    }
    for row in 1..dimension {
        let row_offset = 1 + row * dimension;
        costs[0] += values[row_offset];
        for column in 1..dimension {
            let above = costs[column];
            let left = costs[column - 1];
            costs[column] = above.min(left) + values[row_offset + column];
        }
    }
    costs[dimension - 1]
}
