fn flood(cells: []const i64, visited: *[256]bool, rows: usize, cols: usize, row: isize, col: isize) void {
    if (row < 0 or col < 0 or row >= @as(isize, @intCast(rows)) or col >= @as(isize, @intCast(cols))) return;
    const index = @as(usize, @intCast(row)) * cols + @as(usize, @intCast(col));
    if (cells[index] != 1 or visited[index]) return;
    visited[index] = true;
    for (0..3) |ri| {
        for (0..3) |ci| {
            const dr: isize = @as(isize, @intCast(ri)) - 1;
            const dc: isize = @as(isize, @intCast(ci)) - 1;
            if (dr != 0 or dc != 0) flood(cells, visited, rows, cols, row + dr, col + dc);
        }
    }
}

pub export fn count_islands_in_matrix(values: [*]const i64, length: usize) i64 {
    if (length < 3 or values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 16) return -1;
    const rows: usize = @intCast(values[0]);
    const cols: usize = @intCast(values[1]);
    if (length != 2 + rows * cols) return -1;
    for (values[2..length]) |cell| if (cell != 0 and cell != 1) return -1;
    const cells = values[2..length];
    var visited: [256]bool = @splat(false);
    var count: i64 = 0;
    for (0..rows) |row| {
        for (0..cols) |col| {
            const index = row * cols + col;
            if (cells[index] == 1 and !visited[index]) {
                count += 1;
                flood(cells, &visited, rows, cols, @intCast(row), @intCast(col));
            }
        }
    }
    return count;
}
