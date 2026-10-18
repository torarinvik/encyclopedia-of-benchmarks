#include <stddef.h>
#include <stdint.h>

int64_t permutation_count(const int64_t *input, size_t input_length) {
    if (input == NULL || input_length != 2u) return -1;
    const int64_t n = input[0], r = input[1];
    if (n < 0 || n > 18 || r < 0 || r > 18) return -1;
    int64_t result = 1;
    if (r > n) {
        for (int64_t factor = 2; factor <= n; ++factor) result *= factor;
    } else {
        for (int64_t i = 0; i < r; ++i) result *= n - i;
    }
    return result;
}
