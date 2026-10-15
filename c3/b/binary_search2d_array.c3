module binary_search2d_array;

fn long search_row(long* matrix, long row_base, long low, long high, long target) {
    while (low <= high) {
        long middle = low + (high - low) / 2;
        long value = matrix[row_base + middle];
        if (value == target) return middle;
        if (value < target) {
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return -1;
}

fn long binary_search2d_array(long* values, usz length) @export("binary_search2d_array") {
    if (values == null || length < 3) return -1;
    long rows = values[0];
    long cols = values[1];
    long target = values[2];
    if (rows < 2 || rows > 32 || cols < 3 || cols > 32) return -1;
    if (length != (usz)(3 + rows * cols)) return -1;
    long* matrix = values + 3;
    long middle_col = cols / 2;
    long start_row = 0;
    long end_row = rows - 1;
    while (start_row < end_row - 1) {
        long middle_row = start_row + (end_row - start_row) / 2;
        long value = matrix[middle_row * cols + middle_col];
        if (value == target) return middle_row * cols + middle_col;
        if (value < target) {
            start_row = middle_row;
        } else {
            end_row = middle_row;
        }
    }
    if (matrix[start_row * cols + middle_col] == target) return start_row * cols + middle_col;
    if (matrix[end_row * cols + middle_col] == target) return end_row * cols + middle_col;
    if (target <= matrix[start_row * cols + middle_col - 1]) {
        long col = search_row(matrix, start_row * cols, 0, middle_col - 1, target);
        return col < 0 ? -1 : start_row * cols + col;
    }
    if (target >= matrix[start_row * cols + middle_col + 1] && target <= matrix[start_row * cols + cols - 1]) {
        long col = search_row(matrix, start_row * cols, middle_col + 1, cols - 1, target);
        return col < 0 ? -1 : start_row * cols + col;
    }
    if (target <= matrix[end_row * cols + middle_col - 1]) {
        long col = search_row(matrix, end_row * cols, 0, middle_col - 1, target);
        return col < 0 ? -1 : end_row * cols + col;
    }
    long col = search_row(matrix, end_row * cols, middle_col + 1, cols - 1, target);
    return col < 0 ? -1 : end_row * cols + col;
}
