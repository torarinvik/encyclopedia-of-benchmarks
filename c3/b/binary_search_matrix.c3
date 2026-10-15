module binary_search_matrix;

const usz MAX_DIMENSION = 32;

fn long search_row(long* values, usz base, long lower, long upper, long target) {
    long middle = (lower + upper) / 2;
    long value = values[base + (usz)middle];
    if (value == target) return middle;
    if (lower >= upper) return -1;
    if (value < target) return search_row(values, base, middle + 1, upper, target);
    return search_row(values, base, lower, middle - 1, target);
}

fn long binary_search_matrix(long* values, usz length) @export("binary_search_matrix") {
    if (values == null || length < 3) return -1;
    long rows_value = values[0], columns_value = values[1], target = values[2];
    if (rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    if (length != 3 + rows * columns) return -1;
    long* matrix = values + 3;
    if (matrix[0] == target) return 0;
    for (usz row = 0; row < rows && matrix[row * columns] < target; row++) {
        long column = search_row(matrix, row * columns, 0, (long)columns - 1, target);
        if (column != -1) return (long)(row * columns) + column;
    }
    return -1;
}
