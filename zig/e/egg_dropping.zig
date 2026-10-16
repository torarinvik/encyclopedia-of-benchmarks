const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_EGGS: usize = 12;
const MAX_FLOORS: usize = 128;
const FLOOR_WIDTH: usize = MAX_FLOORS + 1;

pub export fn egg_dropping(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return INVALID_RESULT;
    if (input[0] < 1 or input[0] > @as(i64, MAX_EGGS) or
        input[1] < 1 or input[1] > @as(i64, MAX_FLOORS)) return INVALID_RESULT;

    const eggs: usize = @intCast(input[0]);
    const floors: usize = @intCast(input[1]);
    var dp: [(MAX_EGGS + 1) * FLOOR_WIDTH]i64 = @splat(0);

    for (1..eggs + 1) |egg| dp[egg * FLOOR_WIDTH + 1] = 1;
    for (1..floors + 1) |floor| dp[FLOOR_WIDTH + floor] = @intCast(floor);
    for (2..eggs + 1) |egg| {
        for (2..floors + 1) |floor| {
            var best: i64 = 9223372036854775807;
            for (1..floor + 1) |drop| {
                const breaks = dp[(egg - 1) * FLOOR_WIDTH + drop - 1];
                const survives = dp[egg * FLOOR_WIDTH + floor - drop];
                const worst = 1 + @max(breaks, survives);
                best = @min(best, worst);
            }
            dp[egg * FLOOR_WIDTH + floor] = best;
        }
    }
    return dp[eggs * FLOOR_WIDTH + floors];
}
