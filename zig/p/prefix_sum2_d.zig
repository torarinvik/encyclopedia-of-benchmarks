const MAX_DIMENSION: usize = 16;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn prefix_sum2_d(input: [*]const i64, length: usize) i64 {
    if (length < 7) return INVALID_RESULT;
    const raw_rows = input[0];
    const raw_cols = input[1];
    if (raw_rows < 1 or raw_rows > MAX_DIMENSION or raw_cols < 1 or raw_cols > MAX_DIMENSION) return INVALID_RESULT;
    const rows: usize = @intCast(raw_rows);
    const cols: usize = @intCast(raw_cols);
    if (length != 2 + rows * cols + 4) return INVALID_RESULT;
    const query = 2 + rows * cols;
    const row1v = input[query];
    const col1v = input[query + 1];
    const row2v = input[query + 2];
    const col2v = input[query + 3];
    if (row1v < 0 or col1v < 0 or row2v < row1v or col2v < col1v or
        @as(u64, @intCast(row2v)) >= rows or @as(u64, @intCast(col2v)) >= cols) return INVALID_RESULT;
    var prefix = [_]i64{0} ** ((MAX_DIMENSION + 1) * (MAX_DIMENSION + 1));
    for (0..rows) |i| {
        for (0..cols) |j| {
            const value = input[2 + i * cols + j];
            if (value < -1000 or value > 1000) return INVALID_RESULT;
            const at = (i + 1) * (MAX_DIMENSION + 1) + j + 1;
            prefix[at] = value + prefix[i * (MAX_DIMENSION + 1) + j + 1] +
                prefix[(i + 1) * (MAX_DIMENSION + 1) + j] - prefix[i * (MAX_DIMENSION + 1) + j];
        }
    }
    const row1: usize = @intCast(row1v);
    const col1: usize = @intCast(col1v);
    const row2: usize = @intCast(row2v);
    const col2: usize = @intCast(col2v);
    const stride = MAX_DIMENSION + 1;
    return prefix[(row2 + 1) * stride + col2 + 1] - prefix[row1 * stride + col2 + 1] -
        prefix[(row2 + 1) * stride + col1] + prefix[row1 * stride + col1];
}
