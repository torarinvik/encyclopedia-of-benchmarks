#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 34
#define INVALID_RESULT (-1)

int64_t minimum_coin_change_combinations(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;

    const int64_t target = values[0];
    const int64_t count_value = values[1];
    if (target < -64 || target > 64 || count_value < 0 || count_value > 32) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return INVALID_RESULT;

    int64_t previous = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t coin = values[index + 2];
        if (coin < 1 || coin > 64 || coin <= previous) return INVALID_RESULT;
        previous = coin;
    }

    if (target < 0) return 0;
    int64_t ways[65] = {0};
    ways[0] = 1;
    for (size_t index = 0; index < count; ++index) {
        const size_t coin = (size_t)values[index + 2];
        for (size_t amount = coin; amount <= (size_t)target; ++amount) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[(size_t)target];
}
