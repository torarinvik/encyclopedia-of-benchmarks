export fn validate_sudoku_board(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 81) return -1;
    for (0..81) |i| {
        const value = input[i];
        if (value != '.' and (value < '1' or value > '9')) return -1;
    }
    if (output == null or capacity < 1) return -2;
    var rows = [_]u16{0} ** 9;
    var columns = [_]u16{0} ** 9;
    var boxes = [_]u16{0} ** 9;
    var valid = true;
    for (0..81) |i| {
        const value = input[i];
        if (value == '.') continue;
        const row = i / 9; const col = i % 9; const bx = (row / 3) * 3 + col / 3;
        const bit: u16 = @as(u16, 1) << @intCast(value - '0');
        if (rows[row] & bit != 0 or columns[col] & bit != 0 or boxes[bx] & bit != 0) valid = false;
        rows[row] |= bit; columns[col] |= bit; boxes[bx] |= bit;
    }
    output[0] = @intFromBool(valid);
    return 1;
}
