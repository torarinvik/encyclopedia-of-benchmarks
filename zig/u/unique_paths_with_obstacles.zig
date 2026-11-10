/// Count right/down paths through a packed obstacle grid.
const MAX_ROWS: i64 = 20;
const MAX_COLUMNS: i64 = 20;

export fn unique_paths_with_obstacles(input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const rows_value = input[0];
    const columns_value = input[1];
    if (rows_value < 1 or rows_value > MAX_ROWS or
        columns_value < 1 or columns_value > MAX_COLUMNS) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    if (length != 2 + rows * columns) return -1;

    var paths: [MAX_COLUMNS]u64 = @splat(0);
    paths[0] = 1;
    var cells_seen: u64 = 0;
    var left: u64 = 0;
    var index: usize = 2;
    while (index < length) {
        left = 0;
        for (0..columns) |column| {
            const obstacle: u64 = @bitCast(input[index]);
            cells_seen |= obstacle;
            left = if (obstacle == 0) left + paths[column] else 0;
            paths[column] = left;
            index += 1;
        }
    }
    if (cells_seen > 1) return -1;
    return @intCast(left);
}
