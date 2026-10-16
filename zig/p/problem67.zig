const MAX_ROWS: i64 = 100;
const MAX_VALUES: usize = 5050;

export fn problem67(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_VALUES + 1) return -1;
    const rows = input[0];
    if (rows < 1 or rows > MAX_ROWS or length != @as(usize, @intCast(@divTrunc(rows * (rows + 1), 2))) + 1) return -1;
    var best = [_]i64{0} ** MAX_VALUES;
    const value_count = length - 1;
    for (0..value_count) |index| {
        const value = input[index + 1];
        if (value < 0 or value > 1_000_000) return -1;
        best[index] = value;
    }
    var row: i64 = rows - 1;
    while (row > 0) : (row -= 1) {
        const parent_start: usize = @intCast(@divTrunc((row - 1) * row, 2));
        const child_start: usize = @intCast(@divTrunc(row * (row + 1), 2));
        var column: usize = 0;
        while (column < @as(usize, @intCast(row))) : (column += 1) {
            const parent = parent_start + column;
            const child = child_start + column;
            best[parent] += @max(best[child], best[child + 1]);
        }
    }
    return best[0];
}
