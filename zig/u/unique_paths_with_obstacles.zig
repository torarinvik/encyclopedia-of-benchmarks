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
    for (2..length) |index| {
        if (input[index] != 0 and input[index] != 1) return -1;
    }

    var paths: [MAX_COLUMNS]i64 = @splat(0);
    paths[0] = 1;
    for (0..rows) |row| {
        for (0..columns) |column| {
            const obstacle = input[2 + row * columns + column];
            if (obstacle == 1) paths[column] = 0
            else if (column > 0) paths[column] += paths[column - 1];
        }
    }
    return paths[columns - 1];
}
