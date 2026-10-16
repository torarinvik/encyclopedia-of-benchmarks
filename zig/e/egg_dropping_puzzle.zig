const MAX_EGGS: usize = 8;
const MAX_FLOORS: usize = 32;

export fn egg_dropping_puzzle(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?;
    const eggs_value = values[0];
    const floors_value = values[1];
    if (eggs_value < 1 or eggs_value > MAX_EGGS or floors_value < 1 or floors_value > MAX_FLOORS) return -1;

    const eggs: usize = @intCast(eggs_value);
    const floors: usize = @intCast(floors_value);
    var dp: [MAX_EGGS + 1][MAX_FLOORS + 1]i64 = @splat(@splat(0));
    for (1..eggs + 1) |egg| dp[egg][1] = 1;
    for (1..floors + 1) |floor_count| dp[1][floor_count] = @intCast(floor_count);

    for (2..eggs + 1) |egg| {
        for (2..floors + 1) |floor_count| {
            var best: i64 = MAX_FLOORS + 1;
            for (1..floor_count + 1) |drop_floor| {
                const broken = dp[egg - 1][drop_floor - 1];
                const survives = dp[egg][floor_count - drop_floor];
                const worst = if (broken > survives) broken else survives;
                const candidate = worst + 1;
                if (candidate < best) best = candidate;
            }
            dp[egg][floor_count] = best;
        }
    }
    return dp[eggs][floors];
}
