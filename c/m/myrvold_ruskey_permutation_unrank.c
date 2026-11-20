#include <stddef.h>
#include <stdint.h>

int64_t myrvold_ruskey_permutation_unrank(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 3) return -1;
    if (length != 2) return -1;

    const int64_t n_value = input[0];
    const int64_t rank_value = input[1];
    if (n_value < 0 || n_value > 8 || rank_value < 0) return -1;
    const size_t n = (size_t)n_value;
    int64_t factorial = 1;
    for (size_t factor = 2; factor <= n; ++factor) factorial *= (int64_t)factor;
    if (rank_value >= factorial) return -1;

    const size_t required = 8 * n;
    if (output == NULL || capacity < required) return -2;

    int64_t permutation[8] = {0};
    for (size_t i = 0; i < n; ++i) permutation[i] = (int64_t)i;
    int64_t remainder = rank_value;
    size_t size = n;
    while (size > 0) {
        const size_t choice = (size_t)(remainder % (int64_t)size);
        remainder /= (int64_t)size;
        const size_t last = size - 1;
        const int64_t held = permutation[last];
        permutation[last] = permutation[choice];
        permutation[choice] = held;
        --size;
    }

    for (size_t i = 0; i < n; ++i) {
        const uint64_t value = (uint64_t)permutation[i];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[8 * i + byte] = (uint8_t)(value >> (8 * byte));
        }
    }
    return (int64_t)required;
}
