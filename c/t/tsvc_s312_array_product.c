#include <stddef.h>
#include <stdint.h>

#define MAX_N 48
#define MAX_INPUT_LENGTH (1 + MAX_N)
#define MAX_VALUE INT64_C(2)

int64_t tsvc_s312_array_product(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 0 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + n) return -1;

    int64_t product = 1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value < 0 || value > MAX_VALUE) return -1;
        product *= value;
    }
    return product;
}
