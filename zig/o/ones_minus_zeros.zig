const MAX_CELLS: usize = 100_000;
const MAX_DIMENSION: i64 = 100_000;

fn readCount(output: [*]const u8, cell: usize) i64 {
    const position = 4 * cell;
    const encoded = @as(u32, output[position]) |
        (@as(u32, output[position + 1]) << 8) |
        (@as(u32, output[position + 2]) << 16) |
        (@as(u32, output[position + 3]) << 24);
    return @intCast(encoded);
}

fn writeI32(output: [*]u8, cell: usize, value: i64) void {
    const encoded: u32 = @bitCast(@as(i32, @intCast(value)));
    const position = 4 * cell;
    output[position] = @truncate(encoded);
    output[position + 1] = @truncate(encoded >> 8);
    output[position + 2] = @truncate(encoded >> 16);
    output[position + 3] = @truncate(encoded >> 24);
}

export fn ones_minus_zeros(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or values[0] < 1 or values[0] > MAX_DIMENSION or
        values[1] < 1 or values[1] > MAX_DIMENSION) return -1;
    const rows: usize = @intCast(values[0]);
    const columns: usize = @intCast(values[1]);
    if (rows > MAX_CELLS / columns) return -1;
    const cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (0..cells) |cell| {
        const value = values[2 + cell];
        if (value != 0 and value != 1) return -1;
    }
    const required = 4 * cells;
    if (output_capacity < required) return -2;
    @memset(output[0..required], 0);

    var row_zero_ones: i64 = 0;
    var column_zero_ones: i64 = 0;
    for (0..rows) |row| {
        for (0..columns) |column| {
            if (values[2 + row * columns + column] == 0) continue;
            if (row == 0) {
                row_zero_ones += 1;
            } else {
                const slot = row * columns;
                writeI32(output, slot, readCount(output, slot) + 1);
            }
            if (column == 0) {
                column_zero_ones += 1;
            } else {
                writeI32(output, column, readCount(output, column) + 1);
            }
        }
    }

    var row = rows;
    while (row > 1) {
        row -= 1;
        const row_slot = row * columns;
        const row_ones = readCount(output, row_slot);
        for (0..columns) |column| {
            const column_ones = if (column == 0) column_zero_ones else readCount(output, column);
            const difference = 2 * row_ones + 2 * column_ones -
                @as(i64, @intCast(rows)) - @as(i64, @intCast(columns));
            writeI32(output, row_slot + column, difference);
        }
    }
    for (0..columns) |column| {
        const column_ones = if (column == 0) column_zero_ones else readCount(output, column);
        const difference = 2 * row_zero_ones + 2 * column_ones -
            @as(i64, @intCast(rows)) - @as(i64, @intCast(columns));
        writeI32(output, column, difference);
    }
    return @intCast(cells);
}
