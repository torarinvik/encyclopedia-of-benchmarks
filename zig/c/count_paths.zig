/// Count four-neighbor vertex-simple grid paths by recursive DFS.
fn countFrom(values: []const i64, rows: usize, cols: usize, row: isize, col: isize, visited: u32) i64 {
    if (row < 0 or col < 0 or row >= @as(isize, @intCast(rows)) or col >= @as(isize, @intCast(cols))) return 0;
    const index = @as(usize, @intCast(row)) * cols + @as(usize, @intCast(col));
    const mask = @as(u32, 1) << @intCast(index);
    if (values[2 + index] == 1 or (visited & mask) != 0) return 0;
    if (@as(usize, @intCast(row)) == rows - 1 and @as(usize, @intCast(col)) == cols - 1) return 1;
    const seen = visited | mask;
    return countFrom(values, rows, cols, row + 1, col, seen)
        + countFrom(values, rows, cols, row - 1, col, seen)
        + countFrom(values, rows, cols, row, col + 1, seen)
        + countFrom(values, rows, cols, row, col - 1, seen);
}

pub export fn count_paths(values: [*]const i64, length: usize) i64 {
    if (length < 3 or values[0] < 1 or values[0] > 5 or values[1] < 1 or values[1] > 5) return -1;
    const rows: usize = @intCast(values[0]);
    const cols: usize = @intCast(values[1]);
    if (rows * cols > 25 or length != 2 + rows * cols) return -1;
    const slice = values[0..length];
    for (slice[2..]) |cell| if (cell != 0 and cell != 1) return -1;
    return countFrom(slice, rows, cols, 0, 0, 0);
}
