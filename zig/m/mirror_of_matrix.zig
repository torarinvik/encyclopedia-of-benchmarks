const MAX_DIMENSION: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 259;

fn storeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

export fn mirror_of_matrix(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_rows = values[0];
    const raw_columns = values[1];
    if (raw_rows < 1 or raw_rows > MAX_DIMENSION or
        raw_columns < 1 or raw_columns > MAX_DIMENSION) return -1;
    const rows: usize = @intCast(raw_rows);
    const columns: usize = @intCast(raw_columns);
    const cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;
    for (0..cell_count) |index| {
        const cell = values[2 + index];
        if (cell < -2147483648 or cell > 2147483647) return -1;
    }

    const byte_count = 4 * cell_count;
    if (output == null or output_capacity < byte_count) return -2;
    for (0..rows) |row| {
        for (0..columns) |column| {
            const source_index = 2 + row * columns + (columns - 1 - column);
            storeI32Le(output, 4 * (row * columns + column), @intCast(values[source_index]));
        }
    }
    return @intCast(byte_count);
}
