#include <stddef.h>
#include <stdint.h>

int64_t reverse_letters(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[i + 1];
        if (value == 32) {
            if (i == 0 || i + 1 == n || input[i] == 32) return -1;
        } else if (value < 33 || value > 126) return -1;
    }
    if (output == NULL || capacity < n + 1) return -2;
    size_t start = 0;
    while (start < n) {
        size_t end = start;
        while (end < n && input[end + 1] != 32) ++end;
        for (size_t i = 0; i < end - start + 1; ++i) output[start + i] = (uint8_t)input[end - i];
        if (end < n) output[end] = 32;
        start = end + 1;
    }
    output[n] = 0;
    return (int64_t)n;
}
