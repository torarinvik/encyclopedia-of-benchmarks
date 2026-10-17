module sparse_matrix;

// Return whether strictly more than half of a matrix's entries are zero.
fn long sparse_matrix(long* values, usz length) @export("sparse_matrix") {
    if (values == null || length < 2 || length > 4099) return -1;
    long rows_value = values[0];
    long columns_value = values[1];
    if (rows_value < 1 || rows_value > 64 || columns_value < 1 || columns_value > 64) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz cells = rows * columns;
    if (length != 2 + cells) return -1;
    long zero_count = 0;
    for (usz index = 0; index < cells; index++) {
        long value = values[2 + index];
        if (value < -2147483648 || value > 2147483647) return -1;
        if (value == 0) zero_count++;
    }
    return zero_count > (long)(cells / 2) ? 1 : 0;
}
