#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 3 * MAX_N)
#define MAX_VALUE INT64_C(1000000)

int64_t tsvc_s4115_indexed_gather_product_sum(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + 3 * n) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t index = input[1 + i];
        const int64_t a_value = input[1 + n + i];
        const int64_t b_value = input[1 + 2 * n + i];
        if (index < 0 || index >= (int64_t)n) return -1;
        if (a_value < 0 || a_value > MAX_VALUE || b_value < 0 || b_value > MAX_VALUE) return -1;
    }

    int64_t sum = 0;
    for (size_t i = 0; i < n; ++i) {
        const size_t index = (size_t)input[1 + i];
        sum += input[1 + n + i] * input[1 + 2 * n + index];
    }
    return sum;
}
