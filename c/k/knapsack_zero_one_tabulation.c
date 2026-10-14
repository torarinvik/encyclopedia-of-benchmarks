/* Tabulated 0/1 knapsack with one reusable row and portable integer operations. */
#include <stddef.h>
#include <stdint.h>

int64_t knapsack_zero_one_tabulation(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 258) return -1;
    if (packed[0] < 0 || packed[0] > 512 || packed[1] < 0 || packed[1] > 128) return -1;
    const size_t capacity = (size_t)packed[0];
    const size_t item_count = (size_t)packed[1];
    if (length != 2 + 2 * item_count) return -1;
    for (size_t item = 0; item < item_count; ++item) {
        const int64_t weight = packed[2 + 2 * item];
        const int64_t value = packed[3 + 2 * item];
        if (weight < 1 || weight > 4096 || value < 0 || value > 1000000000) return -1;
    }

    int64_t dp[513] = {0};
    const size_t width = capacity + 1;
    const size_t steps = item_count * width;
    for (size_t step = 0; step < steps; ++step) {
        const size_t item = step / width;
        const size_t current_capacity = capacity - step % width;
        const size_t weight = (size_t)packed[2 + 2 * item];
        const int64_t value = packed[3 + 2 * item];
        if (weight <= current_capacity) {
            const int64_t candidate = dp[current_capacity - weight] + value;
            if (candidate > dp[current_capacity]) dp[current_capacity] = candidate;
        }
    }
    return dp[capacity];
}
