const MAX_DIMENSION: usize = 63;
const MAX_INPUT_VALUES: usize = 2 + MAX_DIMENSION * MAX_DIMENSION;
const MAX_ABS_CELL: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn sparsity(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0];
    let columns_value = values[1];
    if !(1..=MAX_DIMENSION as i64).contains(&rows_value) ||
        !(1..=MAX_DIMENSION as i64).contains(&columns_value) { return INVALID_RESULT; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let total = rows * columns;
    if length != 2 + total { return INVALID_RESULT; }

    let mut zero_count = 0usize;
    for &value in &values[2..] {
        if !(-MAX_ABS_CELL..=MAX_ABS_CELL).contains(&value) { return INVALID_RESULT; }
        if value == 0 { zero_count += 1; }
    }
    zero_count as f64 / total as f64
}
