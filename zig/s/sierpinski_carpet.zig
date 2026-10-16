const INVALID_RESULT: i64 = -1;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn isFilled(row0: usize, col0: usize) bool {
    var row = row0;
    var col = col0;
    while (row != 0 or col != 0) {
        if (row % 3 == 1 and col % 3 == 1) return false;
        row /= 3;
        col /= 3;
    }
    return true;
}

export fn sierpinski_carpet(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length != 3) return INVALID_RESULT;
    const values = input.?[0..length];
    const depth = values[0];
    const filled = values[1];
    const hole = values[2];
    if (depth < 0 or depth > 4 or filled < 32 or filled > 126 or
        hole < 32 or hole > 126 or filled == hole) return INVALID_RESULT;
    var side: usize = 1;
    var level: i64 = 0;
    while (level < depth) : (level += 1) side *= 3;
    const needed = 8 + side * side + side - 1;
    if (output == null or capacity < needed) return -2;
    const result = output.?[0..needed];
    writeI64Le(result, 0, @intCast(side));
    var out: usize = 8;
    for (0..side) |row| {
        for (0..side) |col| {
            result[out] = @intCast(if (isFilled(row, col)) filled else hole);
            out += 1;
        }
        if (row + 1 < side) {
            result[out] = 10;
            out += 1;
        }
    }
    return @intCast(needed);
}
