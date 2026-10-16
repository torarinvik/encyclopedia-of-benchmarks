const MAX_DIMENSION: i64 = 32;
const MAX_INPUT_LENGTH: usize = 2053;

export fn checkequal(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;

    const rows_a = values[0];
    const columns_a = values[1];
    const rows_b = values[2];
    const columns_b = values[3];
    if (rows_a < 0 or rows_a > MAX_DIMENSION or columns_a < 0 or columns_a > MAX_DIMENSION
        or rows_b < 0 or rows_b > MAX_DIMENSION or columns_b < 0 or columns_b > MAX_DIMENSION) return -1;

    const count_a: usize = @intCast(rows_a * columns_a);
    const count_b: usize = @intCast(rows_b * columns_b);
    if (length != 4 + count_a + count_b) return -1;
    if (rows_a != rows_b or columns_a != columns_b) return 0;
    for (0..count_a) |index| {
        if (values[4 + index] != values[4 + count_a + index]) return 0;
    }
    return 1;
}
