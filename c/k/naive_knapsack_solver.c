#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 30
#define LIMIT INT64_C(1000000)

int64_t naive_knapsack_solver(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_ITEMS + 2) return -1;
    const int64_t capacity = values[0], count = values[1];
    if (capacity < 0 || capacity > LIMIT || count < 0 || count > MAX_ITEMS || length != (size_t)count + 2) return -1;
    int64_t weight = 0, mask = 0;
    for (size_t i = 0; i < (size_t)count; ++i) {
        const int64_t item = values[i + 2];
        if (item < 0 || item > LIMIT) return -1;
        if (weight + item <= capacity) { weight += item; mask |= INT64_C(1) << i; }
    }
    return mask;
}
