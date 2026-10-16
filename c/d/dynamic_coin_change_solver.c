#include <stddef.h>
#include <stdint.h>

#define MAX_AMOUNT 18
#define MAX_COINS 9

int64_t dynamic_coin_change_solver(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_COINS + 2) return -1;
    int64_t amount = input[0], count_value = input[1];
    if (amount < 1 || amount > MAX_AMOUNT || count_value < 1 || count_value > MAX_COINS || length != (size_t)(count_value + 2)) return -1;
    int coins[MAX_COINS];
    int count = (int)count_value, has_one = 0;
    for (int i = 0; i < count; ++i) {
        int64_t coin = input[i + 2];
        if (coin < 1 || coin > 9) return -1;
        coins[i] = (int)coin;
        has_one |= coin == 1;
        for (int j = 0; j < i; ++j) if (coins[i] == coins[j]) return -1;
    }
    if (!has_one) return -1;
    for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j)
        if (coins[i] < coins[j]) { int tmp = coins[i]; coins[i] = coins[j]; coins[j] = tmp; }
    int changes[MAX_AMOUNT + 1][MAX_COINS];
    int sizes[MAX_AMOUNT + 1] = {0};
    for (int value = 1; value <= amount; ++value)
        for (int i = 0; i < count; ++i) if (coins[i] <= value) changes[value][sizes[value]++] = value - coins[i];
    int64_t code = 0, current = amount;
    for (int step = 0; step < MAX_AMOUNT; ++step) {
        int64_t next = INT32_MAX, min_change = INT32_MAX;
        for (int i = 0; i < sizes[current]; ++i) {
            int change = changes[current][i];
            if (change == 0) { next = 0; break; }
            int minimum = INT32_MAX;
            for (int j = 0; j < sizes[change]; ++j) if (changes[change][j] < minimum) minimum = changes[change][j];
            if (minimum < min_change) { min_change = minimum; next = change; }
        }
        if (next == INT32_MAX) return -1;
        code = code * 10 + current - next;
        if (next == 0) return code;
        current = next;
    }
    return -1;
}
