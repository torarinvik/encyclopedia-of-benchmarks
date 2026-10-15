fn search_row(values: &[i64], row_base: i64, low: i64, high: i64, target: i64) -> i64 {
    let (mut lo, mut hi) = (low, high);
    while lo <= hi {
        let middle = lo + (hi - lo) / 2;
        let value = values[(3 + row_base + middle) as usize];
        if value == target { return middle; }
        if value < target { lo = middle + 1; }
        else { hi = middle - 1; }
    }
    -1
}

#[no_mangle]
pub extern "C" fn binary_search2d_array(pointer: *const i64, length: usize) -> i64 {
    if pointer.is_null() || length < 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(pointer, length) };
    let (rows, cols, target) = (values[0], values[1], values[2]);
    if rows < 2 || rows > 32 || cols < 3 || cols > 32 { return -1; }
    if length != 3 + (rows * cols) as usize { return -1; }
    let middle_col = cols / 2;
    let (mut start_row, mut end_row) = (0i64, rows - 1);
    while start_row < end_row - 1 {
        let middle_row = start_row + (end_row - start_row) / 2;
        let value = values[(3 + middle_row * cols + middle_col) as usize];
        if value == target { return middle_row * cols + middle_col; }
        if value < target { start_row = middle_row; }
        else { end_row = middle_row; }
    }
    if values[(3 + start_row * cols + middle_col) as usize] == target { return start_row * cols + middle_col; }
    if values[(3 + end_row * cols + middle_col) as usize] == target { return end_row * cols + middle_col; }
    if target <= values[(3 + start_row * cols + middle_col - 1) as usize] {
        let col = search_row(values, start_row * cols, 0, middle_col - 1, target);
        return if col < 0 { -1 } else { start_row * cols + col };
    }
    if target >= values[(3 + start_row * cols + middle_col + 1) as usize]
        && target <= values[(3 + start_row * cols + cols - 1) as usize] {
        let col = search_row(values, start_row * cols, middle_col + 1, cols - 1, target);
        return if col < 0 { -1 } else { start_row * cols + col };
    }
    if target <= values[(3 + end_row * cols + middle_col - 1) as usize] {
        let col = search_row(values, end_row * cols, 0, middle_col - 1, target);
        return if col < 0 { -1 } else { end_row * cols + col };
    }
    let col = search_row(values, end_row * cols, middle_col + 1, cols - 1, target);
    if col < 0 { -1 } else { end_row * cols + col }
}
