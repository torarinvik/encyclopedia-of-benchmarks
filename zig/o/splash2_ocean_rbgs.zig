const std = @import("std");

const MAX_CELLS: usize = 64;
const MAX_INPUT: usize = 132;

export fn splash2_ocean_rbgs(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const side_value = values[0];
    if (side_value != 4.0 and side_value != 6.0 and side_value != 8.0) return -1;
    const side: usize = @intFromFloat(side_value);
    const cells = side * side;
    if (input_length != 3 + 2 * cells) return -1;
    const eigenvalue_squared = values[1];
    const spacing = values[2];
    if (eigenvalue_squared < 0.0 or eigenvalue_squared > 2.0 or spacing < 0.125 or spacing > 1.0)
        return -1;
    const factor = 4.0 - eigenvalue_squared * spacing * spacing;
    if (!std.math.isFinite(factor) or factor <= 0.0) return -1;

    var grid = [_]f64{0} ** MAX_CELLS;
    var rhs = [_]f64{0} ** MAX_CELLS;
    for (0..cells) |i| {
        grid[i] = values[3 + i];
        rhs[i] = values[3 + cells + i];
        if (grid[i] < -8.0 or grid[i] > 8.0 or rhs[i] < -8.0 or rhs[i] > 8.0) return -1;
    }
    const needed = 1 + cells;
    const out = output orelse return -2;
    if (output_capacity < needed) return -2;

    var max_change: f64 = 0.0;
    for (0..2) |color| {
        for (1..side - 1) |row| {
            for (1..side - 1) |column| {
                if ((row + column) % 2 != color) continue;
                const index = row * side + column;
                const neighbors = grid[index + 1] + grid[index - 1] + grid[index - side] + grid[index + side];
                const updated = (neighbors - rhs[index]) / factor;
                const change = @abs(grid[index] - updated);
                max_change = @max(max_change, change);
                grid[index] = updated;
            }
        }
    }
    out[0] = max_change;
    for (0..cells) |i| out[i + 1] = grid[i];
    return @intCast(needed);
}
