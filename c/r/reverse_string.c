#include <stddef.h>
#include <stdint.h>

int64_t reverse_string(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 33 || input[i + 1] > 126) return -1;
    }
    if (output == NULL || capacity < n + 1) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = (uint8_t)input[n - i];
    output[n] = 0;
    return (int64_t)n;
}
