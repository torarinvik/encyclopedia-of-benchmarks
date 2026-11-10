export fn minimum_path_cost_in_grid(input: [*]const i64, length: usize) i64 {
    if (length < 2 or input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 32) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    const cells = rows * columns;
    const move_offset = 2 + cells;
    if (length != move_offset + cells * columns) return -1;
    for (0..cells) |index| {
        if (input[2 + index] < 0 or input[2 + index] >= cells) return -1;
    }
    for (0..cells * columns) |index| {
        if (input[move_offset + index] < 1 or input[move_offset + index] > 100) return -1;
    }
    var costs: [32]u32 = @splat(0);
    var next_costs: [32]u32 = @splat(0);
    for (0..(rows - 1)) |row| {
        @memset(&next_costs, 65536);
        for (0..columns) |column| {
            const value: usize = @intCast(input[2 + row * columns + column]);
            const base = costs[column] + @as(u32, @intCast(value));
            for (0..columns) |target| {
                const candidate = base + @as(u32, @intCast(input[move_offset + value * columns + target]));
                next_costs[target] = @min(candidate, next_costs[target]);
            }
        }
        costs = next_costs;
    }
    const last_row = 2 + (rows - 1) * columns;
    var minimum: u32 = 65536;
    for (0..columns) |column| {
        const candidate = costs[column] + @as(u32, @intCast(input[last_row + column]));
        if (candidate < minimum) minimum = candidate;
    }
    return minimum;
}
