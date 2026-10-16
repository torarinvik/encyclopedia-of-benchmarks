const std = @import("std");

export fn problem82(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3) return -1;
    const row_value = values[0];
    const column_value = values[1];
    if (row_value < 1 or row_value > 80 or column_value < 1 or column_value > 80) return -1;
    const rows: usize = @intCast(row_value);
    const columns: usize = @intCast(column_value);
    if (length != 2 + rows * columns) return -1;
    for (2..length) |index| {
        if (values[index] < 0 or values[index] > 9999) return -1;
    }

    var costs: [80]i64 = @splat(0);
    for (0..rows) |row| costs[row] = values[2 + row * columns];
    for (1..columns) |column| {
        const offset = 2 + column;
        for (0..rows) |row| costs[row] += values[offset + row * columns];
        for (1..rows) |row| {
            const from_above = costs[row - 1] + values[offset + row * columns];
            costs[row] = @min(costs[row], from_above);
        }
        var row = rows - 1;
        while (row > 0) : (row -= 1) {
            const from_below = costs[row] + values[offset + (row - 1) * columns];
            costs[row - 1] = @min(costs[row - 1], from_below);
        }
    }
    var best = costs[0];
    for (1..rows) |row| best = @min(best, costs[row]);
    return best;
}
