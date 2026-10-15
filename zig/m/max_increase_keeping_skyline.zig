/// Return the total allowable increase while preserving row and column skylines.
export fn max_increase_keeping_skyline(values: [*]const i64, length: usize) i64 {
    const max_grid_size = 50;
    if (length < 2 or length > 1 + max_grid_size * max_grid_size) return -1;
    if (values[0] < 2 or values[0] > max_grid_size) return -1;
    const size: usize = @intCast(values[0]);
    if (length != 1 + size * size) return -1;

    var row_max: [max_grid_size]i64 = @splat(0);
    var column_max: [max_grid_size]i64 = @splat(0);
    for (0..size) |row| {
        for (0..size) |column| {
            const height = values[1 + row * size + column];
            if (height < 0 or height > 100) return -1;
            row_max[row] = @max(row_max[row], height);
            column_max[column] = @max(column_max[column], height);
        }
    }

    var total: i64 = 0;
    for (0..size) |row| {
        for (0..size) |column| {
            const height = values[1 + row * size + column];
            total += @min(row_max[row], column_max[column]) - height;
        }
    }
    return total;
}
