export fn sparse_matrix(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 4099) return -1;
    const packed = values;
    const rows_value = packed[0];
    const columns_value = packed[1];
    if (rows_value < 1 or rows_value > 64 or columns_value < 1 or columns_value > 64) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cells = rows * columns;
    if (length != 2 + cells) return -1;
    var zero_count: usize = 0;
    for (0..cells) |index| {
        const value = packed[2 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        if (value == 0) zero_count += 1;
    }
    return if (zero_count > cells / 2) 1 else 0;
}
