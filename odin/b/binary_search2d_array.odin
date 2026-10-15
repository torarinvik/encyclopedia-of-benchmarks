package binary_search2d_array

import "core:c"

search_row :: proc "contextless" (values: [^]i64, row_base, low, high, target: i64) -> i64 {
    lo, hi := low, high
    for lo <= hi {
        middle := lo + (hi - lo) / 2
        value := values[3 + row_base + middle]
        if value == target do return middle
        if value < target do lo = middle + 1
        else do hi = middle - 1
    }
    return -1
}

@(export)
binary_search2d_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 do return -1
    rows, cols, target := values[0], values[1], values[2]
    if rows < 2 || rows > 32 || cols < 3 || cols > 32 do return -1
    if length != c.size_t(3 + rows * cols) do return -1
    middle_col := cols / 2
    start_row, end_row := i64(0), rows - 1
    for start_row < end_row - 1 {
        middle_row := start_row + (end_row - start_row) / 2
        value := values[3 + middle_row * cols + middle_col]
        if value == target do return middle_row * cols + middle_col
        if value < target do start_row = middle_row
        else do end_row = middle_row
    }
    if values[3 + start_row * cols + middle_col] == target do return start_row * cols + middle_col
    if values[3 + end_row * cols + middle_col] == target do return end_row * cols + middle_col
    if target <= values[3 + start_row * cols + middle_col - 1] {
        col := search_row(values, start_row * cols, 0, middle_col - 1, target)
        if col < 0 do return -1
        return start_row * cols + col
    }
    if target >= values[3 + start_row * cols + middle_col + 1] && target <= values[3 + start_row * cols + cols - 1] {
        col := search_row(values, start_row * cols, middle_col + 1, cols - 1, target)
        if col < 0 do return -1
        return start_row * cols + col
    }
    if target <= values[3 + end_row * cols + middle_col - 1] {
        col := search_row(values, end_row * cols, 0, middle_col - 1, target)
        if col < 0 do return -1
        return end_row * cols + col
    }
    col := search_row(values, end_row * cols, middle_col + 1, cols - 1, target)
    if col < 0 do return -1
    return end_row * cols + col
}
