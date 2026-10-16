/// Top-right staircase search for a strictly increasing integer matrix.
export fn saddleback_search(values: [*]const i64, length: usize) i64 {
    if (length < 3) return -1;
    const rows_value = values[0];
    const columns_value = values[1];
    const target = values[2];
    if (rows_value <= 0 or rows_value > 32 or columns_value <= 0 or columns_value > 32) return -1;
    if (target < -2147483648 or target > 2147483647) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cells = rows * columns;
    if (length != 3 + cells) return -1;
    const matrix = values + 3;
    for (0..cells) |index| {
        const value = matrix[index];
        if (value < -2147483648 or value > 2147483647) return -1;
    }

    var row: usize = 0;
    var column: usize = columns - 1;
    while (row < rows) {
        const value = matrix[row * columns + column];
        if (value == target) return @intCast(row * columns + column + 1);
        if (value < target) {
            row += 1;
        } else if (column == 0) {
            break;
        } else {
            column -= 1;
        }
    }
    return 0;
}
