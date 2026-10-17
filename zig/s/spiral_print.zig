const MAX_CELLS: usize = 16 * 16;
const MAX_INPUT_LENGTH: usize = 259;

fn writeI64Le(output: [*c]u8, offset: usize, value: i32) void {
    var bits: u64 = @bitCast(@as(i64, value));
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits & 0xff);
        bits >>= 8;
    }
}

export fn spiral_print(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 or input[0] > 16 or input[1] < 2 or input[1] > 16) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    const cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;
    var matrix: [MAX_CELLS]i32 = undefined;
    for (0..cell_count) |index| {
        const value = input[2 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        matrix[index] = @intCast(value);
    }
    const required = 8 * cell_count;
    if (output == null or capacity < required) return -2;

    var order: [MAX_CELLS]i32 = undefined;
    var written: usize = 0;
    var top: i32 = 0;
    var bottom: i32 = @intCast(rows) - 1;
    var left: i32 = 0;
    var right: i32 = @intCast(columns) - 1;
    while (top <= bottom and left <= right) {
        var column = left;
        while (column <= right) : (column += 1) {
            order[written] = matrix[@as(usize, @intCast(top)) * columns + @as(usize, @intCast(column))];
            written += 1;
        }
        top += 1;
        var row = top;
        while (row <= bottom) : (row += 1) {
            order[written] = matrix[@as(usize, @intCast(row)) * columns + @as(usize, @intCast(right))];
            written += 1;
        }
        right -= 1;
        if (top <= bottom and left <= right) {
            column = right;
            while (column >= left) : (column -= 1) {
                order[written] = matrix[@as(usize, @intCast(bottom)) * columns + @as(usize, @intCast(column))];
                written += 1;
            }
            bottom -= 1;
        }
        if (top <= bottom and left <= right) {
            row = bottom;
            while (row >= top) : (row -= 1) {
                order[written] = matrix[@as(usize, @intCast(row)) * columns + @as(usize, @intCast(left))];
                written += 1;
            }
            left += 1;
        }
    }
    for (0..written) |index| writeI64Le(output, index * 8, order[index]);
    return @intCast(required);
}
