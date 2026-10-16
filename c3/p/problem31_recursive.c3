module problem31_recursive;

const long MAX_TARGET = 200;
const long[8] COINS = {1, 2, 5, 10, 20, 50, 100, 200};

fn long count_ways(long target, int coin_index) {
    if (target < 0) return 0;
    if (coin_index == 0) return 1;
    long coin = COINS[coin_index];
    return count_ways(target - coin, coin_index) + count_ways(target, coin_index - 1);
}

fn long problem31_recursive(long target) @export("problem31_recursive") {
    if (target < 0 || target > MAX_TARGET) return -1;
    return count_ways(target, 7);
}
