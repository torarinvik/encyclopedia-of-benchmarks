export fn count_negative_numbers_in_sorted_matrix(input: [*]const i64, length: usize) i64 {
    if (length < 3 or length > 514) return -1;
    const rows_value = input[0];
    const columns_value = input[1];
    if (rows_value < 1 or rows_value > 512 or columns_value < 1 or columns_value > 512) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    if (rows * columns > 512 or length != 2 + rows * columns) return -1;

    var nonnegative: usize = 0;
    var bound = columns;
    for (0..rows) |row| {
        var left: usize = 0;
        var right = bound;
        while (left < right) {
            const middle = left + (right - left) / 2;
            const value = input[2 + row * columns + middle];
            if (value >= 0) {
                left = middle + 1;
            } else {
                right = middle;
            }
        }
        bound = left;
        nonnegative += bound;
    }
    return @intCast(rows * columns - nonnegative);
}
