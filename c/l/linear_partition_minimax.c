#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 35
#define MAX_N 32

static int feasible(const int64_t *input, size_t n, size_t groups, int64_t limit) {
    size_t used_groups = 1;
    int64_t current_sum = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[i + 2];
        if (current_sum + value > limit) {
            ++used_groups;
            current_sum = value;
            if (used_groups > groups) return 0;
        } else {
            current_sum += value;
        }
    }
    return 1;
}

int64_t linear_partition_minimax(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > input[0]) return -1;
    size_t n = (size_t)input[0];
    size_t groups = (size_t)input[1];
    if (length != n + 2) return -1;

    int64_t low = 0;
    int64_t high = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[i + 2];
        if (value < 0 || value > 1000) return -1;
        if (value > low) low = value;
        high += value;
    }
    while (low < high) {
        int64_t middle = low + (high - low) / 2;
        if (feasible(input, n, groups, middle)) high = middle;
        else low = middle + 1;
    }
    return low;
}
