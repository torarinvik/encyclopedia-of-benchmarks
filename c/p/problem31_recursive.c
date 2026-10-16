#include <stdint.h>

#define MAX_TARGET 200

static const int64_t COINS[] = {1, 2, 5, 10, 20, 50, 100, 200};

static int64_t problem31_recursive_count(int64_t target, int coin_index)
{
    if (target < 0) return 0;
    if (coin_index == 0) return 1;
    const int64_t coin = COINS[coin_index];
    return problem31_recursive_count(target - coin, coin_index) +
           problem31_recursive_count(target, coin_index - 1);
}

int64_t problem31_recursive(int64_t target)
{
    if (target < 0 || target > MAX_TARGET) return -1;
    return problem31_recursive_count(target, 7);
}
