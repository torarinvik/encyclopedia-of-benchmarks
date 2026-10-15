/// Count right-and-down paths with one row of dynamic programming.
export fn unique_paths(rows: u64, columns: u64) i64 {
    if (rows == 0 or columns == 0 or rows > 34 or columns > 34) return -1;
    const width = @min(rows, columns);
    const height = @max(rows, columns);
    var paths: [34]i64 = @splat(0);
    for (0..@intCast(width)) |column| paths[column] = 1;
    for (1..@intCast(height)) |_| {
        for (1..@intCast(width)) |column| paths[column] += paths[column - 1];
    }
    return paths[@intCast(width - 1)];
}
