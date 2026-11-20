#include <stddef.h>
#include <stdint.h>

int64_t random_permutation_cycle_cap_count(const int64_t *input, size_t input_length) {
    if (input == NULL || input_length != 2u) return -1;
    const int64_t n = input[0];
    const int64_t cap = input[1];
    if (n < 1 || n > 20 || cap < 1 || cap > n) return -1;

    int64_t counts[21] = {0};
    counts[0] = 1;
    for (int64_t size = 1; size <= n; ++size) {
        int64_t total = 0;
        int64_t cycle_choices = 1;
        const int64_t limit = size < cap ? size : cap;
        for (int64_t cycle_length = 1; cycle_length <= limit; ++cycle_length) {
            if (cycle_length > 1) cycle_choices *= size - cycle_length + 1;
            total += cycle_choices * counts[size - cycle_length];
        }
        counts[size] = total;
    }
    return counts[n];
}
