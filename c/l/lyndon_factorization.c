#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 256

int64_t lyndon_factorization(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (length < 1 || length > MAX_SEQUENCE_LENGTH + 1 || input == NULL) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_SEQUENCE_LENGTH || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 97 || input[i + 1] > 122) return -1;
    const size_t required = 2 * n;
    /* Every factor contributes a NUL separator; the bound above is at most 2*n. */
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    size_t start = 0, out = 0;
    while (start < n) {
        size_t candidate = start + 1, match = start;
        while (candidate < n && input[match + 1] <= input[candidate + 1]) {
            if (input[match + 1] < input[candidate + 1]) match = start;
            else ++match;
            ++candidate;
        }
        const size_t factor_length = candidate - match;
        while (start <= match) {
            for (size_t j = 0; j < factor_length; ++j) output[out++] = (uint8_t)input[start + j + 1];
            output[out++] = 0;
            start += factor_length;
        }
    }
    return (int64_t)out;
}
