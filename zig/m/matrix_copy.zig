const MAX_DIMENSION: usize = 32;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |index| output[offset + index] = @truncate(bits >> @intCast(index * 8));
}

export fn matrix_copy(values: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 2 + MAX_DIMENSION * MAX_DIMENSION) return -1;
    const rows_value = values[0];
    const columns_value = values[1];
    if (rows_value < 0 or rows_value > MAX_DIMENSION or columns_value < 0 or columns_value > MAX_DIMENSION) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const element_count = rows * columns;
    if (length != 2 + element_count) return -1;
    for (0..element_count) |index| if (values[2 + index] < -2147483648 or values[2 + index] > 2147483647) return -1;
    const result_rows: usize = if (rows == 0 or columns == 0) 0 else rows;
    const result_columns: usize = if (rows == 0 or columns == 0) 0 else columns;
    const result_count = result_rows * result_columns;
    const output_bytes = (2 + result_count) * 8;
    if (output_capacity < output_bytes) return -2;
    storeI64Le(output, 0, @intCast(result_rows));
    storeI64Le(output, 8, @intCast(result_columns));
    for (0..result_count) |index| storeI64Le(output, 16 + index * 8, values[2 + index]);
    return @intCast(output_bytes);
}
