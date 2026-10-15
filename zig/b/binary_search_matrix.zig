/// Recursive row search matching the pinned matrix-search source.
fn searchRow(values: [*]const i64, base: usize, lower: i64, upper: i64, target: i64) i64 {
    const middle = @divTrunc(lower + upper, 2);
    const value = values[base + @as(usize, @intCast(middle))];
    if (value == target) return middle;
    if (lower >= upper) return -1;
    if (value < target) return searchRow(values, base, middle + 1, upper, target);
    return searchRow(values, base, lower, middle - 1, target);
}

export fn binary_search_matrix(values: [*]const i64, length: usize) i64 {
    if (length < 3) return -1;
    const rows_value = values[0];
    const columns_value = values[1];
    const target = values[2];
    if (rows_value <= 0 or rows_value > 32 or columns_value <= 0 or columns_value > 32) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    if (length != 3 + rows * columns) return -1;
    const matrix = values + 3;
    if (matrix[0] == target) return 0;
    var row: usize = 0;
    while (row < rows and matrix[row * columns] < target) : (row += 1) {
        const column = searchRow(matrix, row * columns, 0, @as(i64, @intCast(columns)) - 1, target);
        if (column != -1) return @as(i64, @intCast(row * columns)) + column;
    }
    return -1;
}
