/// Return the minimum number of unlimited coins needed to reach an amount.
export fn coin_change(input_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 130) return -1;
    const amount = input_values[0];
    const coin_count = input_values[1];
    if (amount < 0 or amount > 512 or coin_count < 0 or coin_count > 128) return -1;
    if (length != 2 + @as(usize, @intCast(coin_count))) return -1;
    for (0..@as(usize, @intCast(coin_count))) |coin_index| {
        const denomination = input_values[2 + coin_index];
        if (denomination < 1 or denomination > 4096) return -1;
    }

    var minimum: [513]i64 = @splat(0);
    for (1..@as(usize, @intCast(amount)) + 1) |current| {
        var best: i64 = 513;
        for (0..@as(usize, @intCast(coin_count))) |coin_index| {
            const coin: usize = @intCast(input_values[2 + coin_index]);
            if (coin <= current and minimum[current - coin] < 513) {
                best = @min(best, minimum[current - coin] + 1);
            }
        }
        minimum[current] = best;
    }
    const result = minimum[@intCast(amount)];
    return if (result < 513) result else -1;
}
