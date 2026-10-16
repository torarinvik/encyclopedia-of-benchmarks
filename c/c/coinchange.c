#include <stddef.h>
#include <stdint.h>

#define MAX_AMOUNT 30
#define MAX_COINS 8

int64_t coinchange(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_COINS + 2) {
        return -1;
    }
    const int64_t amount_value = values[0];
    const int64_t coin_count_value = values[1];
    if (amount_value < 1 || amount_value > MAX_AMOUNT || coin_count_value < 0 || coin_count_value > MAX_COINS) {
        return -1;
    }
    const size_t amount = (size_t)amount_value;
    const size_t coin_count = (size_t)coin_count_value;
    if (length != coin_count + 2) {
        return -1;
    }
    for (size_t index = 0; index < coin_count; ++index) {
        if (values[index + 2] < 1 || values[index + 2] > MAX_AMOUNT) {
            return -1;
        }
    }

    int64_t combinations[MAX_AMOUNT] = {0};
    combinations[0] = 1;
    for (size_t coin_index = 0; coin_index < coin_count; ++coin_index) {
        const size_t coin = (size_t)values[coin_index + 2];
        for (size_t subtotal = coin; subtotal < amount; ++subtotal) {
            combinations[subtotal] += combinations[subtotal - coin];
        }
    }
    return combinations[amount - 1];
}
