const MAX_N: usize = 100;
const INVALID_RESULT: i64 = -10001;

export fn minimum_falling_path_sum(input: [*]const i64, length: usize) i64 {
    if (length < 1 or input[0] < 1 or input[0] > 100) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return INVALID_RESULT;
    for (0..n * n) |index| {
        if (input[1 + index] < -100 or input[1 + index] > 100) return INVALID_RESULT;
    }

    var costs: [MAX_N + 2]u16 = @splat(0);
    var next_costs: [MAX_N]u16 = @splat(0);
    costs[0] = 32768;
    costs[n + 1] = 32768;
    for (0..n) |column| costs[column + 1] = @intCast(input[1 + column] + 100);
    for (1..n) |row| {
        for (0..n) |column| {
            const best = @min(costs[column], costs[column + 1], costs[column + 2]);
            next_costs[column] = best + @as(u16, @intCast(input[1 + row * n + column] + 100));
        }
        @memcpy(costs[1 .. n + 1], next_costs[0..n]);
    }
    var minimum = costs[1];
    for (1..n) |column| minimum = @min(minimum, costs[column + 1]);
    return @as(i64, minimum) - 100 * @as(i64, @intCast(n));
}
