const MAX_N: usize = 100;
const INVALID_RESULT: i64 = -10001;

export fn minimum_falling_path_sum(input: [*]const i64, length: usize) i64 {
    if (length < 1 or input[0] < 1 or input[0] > 100) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return INVALID_RESULT;
    for (0..n * n) |index| {
        if (input[1 + index] < -100 or input[1 + index] > 100) return INVALID_RESULT;
    }

    var costs: [MAX_N]i64 = @splat(0);
    var next_costs: [MAX_N]i64 = @splat(0);
    for (0..n) |column| costs[column] = input[1 + column];
    for (1..n) |row| {
        for (0..n) |column| {
            var best = costs[column];
            if (column > 0 and costs[column - 1] < best) best = costs[column - 1];
            if (column + 1 < n and costs[column + 1] < best) best = costs[column + 1];
            next_costs[column] = best + input[1 + row * n + column];
        }
        costs = next_costs;
    }
    var minimum = costs[0];
    for (1..n) |column| {
        if (costs[column] < minimum) minimum = costs[column];
    }
    return minimum;
}
