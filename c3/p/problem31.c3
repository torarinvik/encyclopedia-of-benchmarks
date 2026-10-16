module problem31;

const long MAX_TARGET = 500;

fn long problem31(long target) @export("problem31") {
    if (target < 0 || target > MAX_TARGET) return -1;
    long[8] coins = {1, 2, 5, 10, 20, 50, 100, 200};
    long[MAX_TARGET + 1] ways = {0};
    ways[0] = 1;
    for (int coin_index = 0; coin_index < 8; coin_index++) {
        long coin = coins[coin_index];
        for (long amount = coin; amount <= target; amount++) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[target];
}
