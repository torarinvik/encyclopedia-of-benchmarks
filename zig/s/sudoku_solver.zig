/// Row-major backtracking Sudoku solver with row, column, and box masks.

fn searchSudoku(board: *[81]i64, rows: *[9]u16, columns: *[9]u16,
    boxes: *[9]u16, position: usize) bool {
    var current = position;
    while (current < 81 and board[current] != 0) current += 1;
    if (current == 81) return true;
    const row = current / 9;
    const column = current % 9;
    const box_index = (row / 3) * 3 + column / 3;
    for (1..10) |digit| {
        const bit: u16 = @as(u16, 1) << @intCast(digit);
        if ((rows[row] & bit) != 0 or (columns[column] & bit) != 0 or (boxes[box_index] & bit) != 0) continue;
        board[current] = @intCast(digit);
        rows[row] |= bit; columns[column] |= bit; boxes[box_index] |= bit;
        if (searchSudoku(board, rows, columns, boxes, current + 1)) return true;
        board[current] = 0;
        rows[row] ^= bit; columns[column] ^= bit; boxes[box_index] ^= bit;
    }
    return false;
}

export fn sudoku_solver(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length != 81) return -1;
    var board: [81]i64 = undefined;
    var rows: [9]u16 = @splat(0);
    var columns: [9]u16 = @splat(0);
    var boxes: [9]u16 = @splat(0);
    for (0..81) |position| {
        const digit = values[position];
        if (digit < 0 or digit > 9) return -1;
        board[position] = digit;
        if (digit == 0) continue;
        const row = position / 9;
        const column = position % 9;
        const box_index = (row / 3) * 3 + column / 3;
        const bit: u16 = @as(u16, 1) << @intCast(digit);
        if ((rows[row] & bit) != 0 or (columns[column] & bit) != 0 or (boxes[box_index] & bit) != 0) return -1;
        rows[row] |= bit; columns[column] |= bit; boxes[box_index] |= bit;
    }
    if (output_capacity < 324) return -2;
    if (!searchSudoku(&board, &rows, &columns, &boxes, 0)) return -1;
    for (0..81) |position| {
        const bits: u32 = @bitCast(@as(i32, @intCast(board[position])));
        for (0..4) |byte|
            output[position * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return 81;
}
