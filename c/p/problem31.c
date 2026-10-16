#include <stddef.h>
#include <stdint.h>

#define MAX_TARGET 500

int64_t problem31(int64_t target)
{
    if (target < 0 || target > MAX_TARGET) return -1;
    static const int64_t coins[] = {1, 2, 5, 10, 20, 50, 100, 200};
    int64_t ways[MAX_TARGET + 1] = {0};
    ways[0] = 1;
    for (size_t coin_index = 0; coin_index < sizeof(coins) / sizeof(coins[0]); ++coin_index) {
        for (int64_t amount = coins[coin_index]; amount <= target; ++amount) {
            ways[amount] += ways[amount - coins[coin_index]];
        }
    }
    return ways[target];
}
