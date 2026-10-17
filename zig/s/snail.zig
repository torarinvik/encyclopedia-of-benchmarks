const MAX_CELLS: usize = 16 * 16;
const MAX_INPUT_LENGTH: usize = 259;

fn writeI32Le(output: []u8, index: usize, value: i32) void {
    const offset = index * 4;
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn snail(values_opt: ?[*]const i32, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (values_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = values_opt.?;
    const rows_value = values[0];
    const columns_value = values[1];
    if (rows_value < 0 or rows_value > 16 or columns_value < 0 or columns_value > 16) return -1;
    if (rows_value == 0 and columns_value != 0) return -1;
    if (columns_value == 1 and rows_value != 1) return -1;

    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;

    const required_bytes = cell_count * 4;
    if (output_opt == null or output_capacity < required_bytes) return -2;
    if (cell_count == 0) return 0;

    var matrix: [MAX_CELLS]i32 = undefined;
    for (0..cell_count) |index| matrix[index] = values[2 + index];
    const output = output_opt.?[0..required_bytes];

    var top: i32 = 0;
    var bottom: i32 = @intCast(rows) - 1;
    var left: i32 = 0;
    var right: i32 = @intCast(columns) - 1;
    var written: usize = 0;
    while (top <= bottom and left <= right) {
        var column = left;
        while (column <= right) : (column += 1) {
            const index = @as(usize, @intCast(top)) * columns + @as(usize, @intCast(column));
            writeI32Le(output, written, matrix[index]);
            written += 1;
        }
        top += 1;

        var row = top;
        while (row <= bottom) : (row += 1) {
            const index = @as(usize, @intCast(row)) * columns + @as(usize, @intCast(right));
            writeI32Le(output, written, matrix[index]);
            written += 1;
        }
        right -= 1;

        if (top <= bottom and left <= right) {
            column = right;
            while (column >= left) : (column -= 1) {
                const index = @as(usize, @intCast(bottom)) * columns + @as(usize, @intCast(column));
                writeI32Le(output, written, matrix[index]);
                written += 1;
            }
            bottom -= 1;
        }

        if (top <= bottom and left <= right) {
            row = bottom;
            while (row >= top) : (row -= 1) {
                const index = @as(usize, @intCast(row)) * columns + @as(usize, @intCast(left));
                writeI32Le(output, written, matrix[index]);
                written += 1;
            }
            left += 1;
        }
    }
    return @intCast(required_bytes);
}
