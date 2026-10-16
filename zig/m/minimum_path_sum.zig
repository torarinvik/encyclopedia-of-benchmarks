const std = @import("std");

export fn minimum_path_sum(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 66) return std.math.minInt(i64);
    const row_value = values[0];
    const column_value = values[1];
    if (row_value < 1 or row_value > 8 or column_value < 1 or column_value > 8) return std.math.minInt(i64);
    const rows: usize = @intCast(row_value);
    const columns: usize = @intCast(column_value);
    if (length != 2 + rows * columns) return std.math.minInt(i64);
    var costs: [8]i64 = @splat(0);
    for (0..rows) |row| {
        for (0..columns) |column| {
            const cell = values[2 + row * columns + column];
            if (cell < 0 or cell > 1000) return std.math.minInt(i64);
            if (row == 0 and column == 0) {
                costs[column] = cell;
            } else if (row == 0) {
                costs[column] = costs[column - 1] + cell;
            } else if (column == 0) {
                costs[column] += cell;
            } else {
                costs[column] = @min(costs[column], costs[column - 1]) + cell;
            }
        }
    }
    return costs[columns - 1];
}
