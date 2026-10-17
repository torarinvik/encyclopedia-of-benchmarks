/// Return whether strictly more than half of a matrix's entries are zero.
#[no_mangle]
pub unsafe extern "C" fn sparse_matrix(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 4099 {
        return -1;
    }
    let packed = std::slice::from_raw_parts(values, length);
    let rows_value = packed[0];
    let columns_value = packed[1];
    if !(1..=64).contains(&rows_value) || !(1..=64).contains(&columns_value) {
        return -1;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != 2 + cells {
        return -1;
    }
    let entries = &packed[2..];
    if entries.iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    let zero_count = entries.iter().filter(|&&value| value == 0).count();
    if zero_count > cells / 2 { 1 } else { 0 }
}
