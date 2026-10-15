/* Unbounded knapsack: take the current item again or skip to the previous item. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 16
#define MAX_CAPACITY 100

static int64_t solve(int item, int capacity, const int64_t *values, const int64_t *weights,
                     int64_t memo[MAX_ITEMS][MAX_CAPACITY + 1])
{
    if (item == 0) return (capacity / (int)weights[0]) * values[0];
    if (memo[item][capacity] >= 0) return memo[item][capacity];
    int64_t skip = solve(item - 1, capacity, values, weights, memo);
    int64_t take = 0;
    if (capacity >= weights[item]) take = values[item] + solve(item, capacity - (int)weights[item], values, weights, memo);
    memo[item][capacity] = take > skip ? take : skip;
    return memo[item][capacity];
}

int64_t unbounded_knapsack(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], capacity_value = input[1];
    if (n_value < 0 || n_value > MAX_ITEMS || capacity_value < 0 || capacity_value > MAX_CAPACITY) return -1;
    size_t n = (size_t)n_value;
    if (length != 2 + 2 * n) return -1;
    if (n == 0) return 0;
    const int64_t *values = input + 2, *weights = input + 2 + n;
    for (size_t i = 0; i < n; ++i)
        if (values[i] < 1 || values[i] > 100 || weights[i] < 1 || weights[i] > 100) return -1;
    int64_t memo[MAX_ITEMS][MAX_CAPACITY + 1];
    for (size_t i = 0; i < MAX_ITEMS; ++i) for (size_t c = 0; c <= MAX_CAPACITY; ++c) memo[i][c] = -1;
    return solve((int)n - 1, (int)capacity_value, values, weights, memo);
}
