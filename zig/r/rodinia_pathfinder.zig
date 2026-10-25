/// Bounded row-wise minimum-cost path through a grid.
export fn rodinia_pathfinder(input: [*]const i64, length: usize) i64 {
    if (length < 4 or length > 3 + 32 * 32) return -1;
    if (input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 32 or
        input[2] < 1 or input[2] > 4) return -1;
    const cols: usize = @intCast(input[0]);
    const rows: usize = @intCast(input[1]);
    const height: usize = @intCast(input[2]);
    const cells = cols * rows;
    if (length != 3 + cells) return -1;
    for (0..cells) |i| if (input[3 + i] < 0 or input[3 + i] > 9) return -1;
    var previous: [32]i64 = @splat(0);
    var current: [32]i64 = @splat(0);
    for (0..cols) |col| previous[col] = input[3 + col];
    var first: usize = 1;
    while (first < rows) : (first += height) {
        const steps = @min(height, rows - first);
        for (0..steps) |step| {
            const row = first + step;
            for (0..cols) |col| {
                var best = previous[col];
                if (col > 0 and previous[col - 1] < best) best = previous[col - 1];
                if (col + 1 < cols and previous[col + 1] < best) best = previous[col + 1];
                current[col] = best + input[3 + row * cols + col];
            }
            for (0..cols) |col| previous[col] = current[col];
        }
    }
    var answer = previous[0];
    for (1..cols) |col| if (previous[col] < answer) { answer = previous[col]; };
    return answer;
}
