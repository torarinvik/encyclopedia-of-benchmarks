#include <stddef.h>
#include <stdint.h>

int64_t functional_graph_cycle_brent(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 67) return -1;
    int64_t n_value = input[0], start_value = input[1];
    if (n_value < 1 || n_value > 64 || start_value < 0 || start_value >= n_value)
        return -1;
    size_t n = (size_t)n_value;
    if (length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= n_value) return -1;

    size_t start = (size_t)start_value;
    size_t checkpoint = start, moving = (size_t)input[start + 2];
    size_t power = 1, period = 1;
    while (checkpoint != moving) {
        if (power == period) {
            checkpoint = moving;
            power *= 2;
            period = 0;
        }
        moving = (size_t)input[moving + 2];
        ++period;
    }
    size_t left = start, right = start;
    for (size_t i = 0; i < period; ++i) right = (size_t)input[right + 2];
    size_t tail = 0;
    while (left != right) {
        left = (size_t)input[left + 2];
        right = (size_t)input[right + 2];
        ++tail;
    }
    return (int64_t)(65 * tail + period);
}
