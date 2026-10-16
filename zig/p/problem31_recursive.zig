const MAX_TARGET: i64 = 200;
const COINS = [_]i64{1, 2, 5, 10, 20, 50, 100, 200};

fn count_ways(target: i64, coin_index: usize) i64 {
    if (target < 0) return 0;
    if (coin_index == 0) return 1;
    const coin = COINS[coin_index];
    return count_ways(target - coin, coin_index) + count_ways(target, coin_index - 1);
}

export fn problem31_recursive(target: i64) i64 {
    if (target < 0 or target > MAX_TARGET) return -1;
    return count_ways(target, 7);
}
