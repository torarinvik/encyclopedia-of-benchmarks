export fn problem15_dp(grid_size: i64) i64 {
    if (grid_size < 0 or grid_size > 20) return -1;
    const size: usize = @intCast(grid_size);
    var counts: [21][21]i64 = @splat(@splat(1));
    for (1..size + 1) |row| {
        for (1..size + 1) |column| {
            counts[row][column] = counts[row - 1][column] + counts[row][column - 1];
        }
    }
    return counts[size][size];
}
