/* Return the minimum number of unlimited coins needed to reach an amount. */
#include <stddef.h>
#include <stdint.h>

int64_t coin_change(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 130) return -1;
    const int64_t amount = packed[0];
    const int64_t coin_count = packed[1];
    if (amount < 0 || amount > 512 || coin_count < 0 || coin_count > 128 ||
        length != (size_t)(2 + coin_count)) return -1;
    for (size_t coin_index = 0; coin_index < (size_t)coin_count; ++coin_index) {
        if (packed[2 + coin_index] < 1 || packed[2 + coin_index] > 4096) return -1;
    }

    int64_t minimum[513];
    minimum[0] = 0;
    for (size_t current = 1; current <= (size_t)amount; ++current) {
        int64_t best = 513;
        for (size_t coin_index = 0; coin_index < (size_t)coin_count; ++coin_index) {
            const size_t coin = (size_t)packed[2 + coin_index];
            if (coin <= current && minimum[current - coin] < 513 &&
                minimum[current - coin] + 1 < best) {
                best = minimum[current - coin] + 1;
            }
        }
        minimum[current] = best;
    }
    return minimum[(size_t)amount] < 513 ? minimum[(size_t)amount] : -1;
}
