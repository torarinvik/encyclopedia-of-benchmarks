#include <stddef.h>
#include <stdint.h>

int64_t z_function(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (length > 256 || (length > 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }
    const size_t required = length * 8;
    if (capacity < required || (required > 0 && output == NULL)) return -2;

    int64_t z[256] = {0};
    size_t left = 0, right = 0;
    for (size_t i = 1; i < length; ++i) {
        if (i <= right) {
            const size_t prior = (size_t)z[i - left];
            const size_t window = right - i + 1;
            z[i] = (int64_t)(window < prior ? window : prior);
        }
        while (i + (size_t)z[i] < length && input[(size_t)z[i]] == input[i + (size_t)z[i]]) {
            ++z[i];
        }
        if (i + (size_t)z[i] > right + 1) {
            left = i;
            right = i + (size_t)z[i] - 1;
        }
    }
    for (size_t i = 0; i < length; ++i) {
        const uint64_t bits = (uint64_t)z[i];
        for (size_t byte = 0; byte < 8; ++byte) output[8 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
