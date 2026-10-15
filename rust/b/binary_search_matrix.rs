/// Recursive row search matching the pinned matrix-search source.
unsafe fn search_row(values: *const i64, base: usize, lower: i64, upper: i64, target: i64) -> i64 {
    let middle = (lower + upper) / 2;
    let value = *values.add(base + middle as usize);
    if value == target { return middle; }
    if lower >= upper { return -1; }
    if value < target { return search_row(values, base, middle + 1, upper, target); }
    search_row(values, base, lower, middle - 1, target)
}

#[no_mangle]
pub unsafe extern "C" fn binary_search_matrix(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -1; }
    let rows_value = *values;
    let columns_value = *values.add(1);
    let target = *values.add(2);
    if rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32 { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    if length != 3 + rows * columns { return -1; }
    let matrix = values.add(3);
    if *matrix == target { return 0; }
    let mut row = 0;
    while row < rows && *matrix.add(row * columns) < target {
        let column = search_row(matrix, row * columns, 0, columns as i64 - 1, target);
        if column != -1 { return (row * columns) as i64 + column; }
        row += 1;
    }
    -1
}
