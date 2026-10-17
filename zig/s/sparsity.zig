const MAX_DIMENSION: usize = 63;
const MAX_INPUT_VALUES: usize = 2 + MAX_DIMENSION * MAX_DIMENSION;
const MAX_ABS_CELL: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn sparsity(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return INVALID_RESULT;
    const values = input.?[0..length];
    const rows_value = values[0];
    const columns_value = values[1];
    if (rows_value < 1 or rows_value > MAX_DIMENSION or columns_value < 1 or columns_value > MAX_DIMENSION)
        return INVALID_RESULT;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const total = rows * columns;
    if (length != 2 + total) return INVALID_RESULT;

    var zero_count: usize = 0;
    for (values[2..]) |value| {
        if (value < -MAX_ABS_CELL or value > MAX_ABS_CELL) return INVALID_RESULT;
        if (value == 0) zero_count += 1;
    }
    return @as(f64, @floatFromInt(zero_count)) / @as(f64, @floatFromInt(total));
}
