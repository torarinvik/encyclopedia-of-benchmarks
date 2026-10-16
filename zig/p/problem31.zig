const MAX_TARGET: usize = 500;
const COINS = [_]usize{1, 2, 5, 10, 20, 50, 100, 200};

export fn problem31(target: i64) i64 {
    if (target < 0 or target > @as(i64, MAX_TARGET)) return -1;
    const target_index: usize = @intCast(target);
    var ways = [_]i64{0} ** (MAX_TARGET + 1);
    ways[0] = 1;
    for (COINS) |coin| {
        var amount = coin;
        while (amount <= target_index) : (amount += 1) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[target_index];
}
