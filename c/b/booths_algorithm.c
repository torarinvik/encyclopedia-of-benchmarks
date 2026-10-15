#include <stddef.h>
#include <stdint.h>

int64_t booths_algorithm(const int64_t *values, size_t length,
                         uint8_t *output, size_t capacity)
{
    if (values == NULL || length == 0 || length > 256) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    if (output == NULL || capacity < length) return -2;

    int64_t failure[512];
    for (size_t index = 0; index < 2 * length; ++index) failure[index] = -1;
    size_t start = 0;
    for (size_t j = 1; j < 2 * length; ++j) {
        const int64_t current = values[j % length];
        int64_t matched = failure[j - start - 1];
        while (matched != -1 && current != values[(start + (size_t)matched + 1) % length]) {
            if (current < values[(start + (size_t)matched + 1) % length]) start = j - (size_t)matched - 1;
            matched = failure[(size_t)matched];
        }
        if (matched == -1 && current != values[start % length]) {
            if (current < values[start % length]) start = j;
            failure[j - start] = -1;
        } else {
            failure[j - start] = matched + 1;
        }
    }

    for (size_t index = 0; index < length; ++index) {
        output[index] = (uint8_t)values[(start + index) % length];
    }
    return (int64_t)length;
}
