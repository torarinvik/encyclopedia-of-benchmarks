const MAX_INPUT: usize = 34;

export fn minimum_coin_change_combinations(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const values = input.?;
    const target_value = values[0];
    const count_value = values[1];
    if (target_value < -64 or target_value > 64 or count_value < 0 or count_value > 32) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;

    var previous: i64 = 0;
    for (0..count) |index| {
        const coin = values[2 + index];
        if (coin < 1 or coin > 64 or coin <= previous) return -1;
        previous = coin;
    }
    if (target_value < 0) return 0;

    const target: usize = @intCast(target_value);
    var ways: [65]i64 = @splat(0);
    ways[0] = 1;
    for (0..count) |coin_index| {
        const coin: usize = @intCast(values[2 + coin_index]);
        var amount = coin;
        while (amount <= target) : (amount += 1) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[target];
}
