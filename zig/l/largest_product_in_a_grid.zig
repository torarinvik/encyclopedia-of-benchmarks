const MAX_INPUT_LENGTH: usize = 3971;
const INVALID_RESULT: i64 = -1;

export fn largest_product_in_a_grid(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const rows = values[0];
    const cols = values[1];
    if (rows < 0 or rows > 63 or cols < 0 or cols > 63) return INVALID_RESULT;

    const row_count: usize = @intCast(rows);
    const col_count: usize = @intCast(cols);
    if (length != 2 + row_count * col_count) return INVALID_RESULT;
    for (2..length) |index| {
        if (values[index] < 0 or values[index] > 1000) return INVALID_RESULT;
    }

    const row_steps = [_]i64{ 0, 1, 1, 1 };
    const col_steps = [_]i64{ 1, 0, 1, -1 };
    var best: i64 = 0;
    for (0..row_count) |row| {
        for (0..col_count) |col| {
            for (0..4) |direction| {
                var product: i64 = 1;
                for (0..4) |offset| {
                    const next_row = @as(i64, @intCast(row)) + @as(i64, @intCast(offset)) * row_steps[direction];
                    const next_col = @as(i64, @intCast(col)) + @as(i64, @intCast(offset)) * col_steps[direction];
                    if (next_row < 0 or next_row >= rows or next_col < 0 or next_col >= cols) {
                        product = 0;
                        break;
                    }
                    const index = 2 + @as(usize, @intCast(next_row)) * col_count + @as(usize, @intCast(next_col));
                    product *= values[index];
                }
                best = @max(best, product);
            }
        }
    }
    return best;
}
