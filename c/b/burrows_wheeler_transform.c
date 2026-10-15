/* Case-sensitive Burrows-Wheeler transform over packed ASCII bytes. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

static int rotation_less(const int64_t *values, size_t n, size_t left, size_t right)
{
    for (size_t offset = 0; offset < n; ++offset) {
        const int64_t a = values[1 + (left + offset) % n];
        const int64_t b = values[1 + (right + offset) % n];
        if (a != b) return a < b;
    }
    return left < right;
}

int64_t burrows_wheeler_transform(const int64_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2) return -1;
    if (values[0] < 1 || values[0] > MAX_LENGTH) return -1;
    const size_t n = (size_t)values[0];
    if (length != n + 1) return -1;
    for (size_t i = 1; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    const size_t output_length = n + 4;
    if (output_capacity < output_length || output == NULL) return -2;

    size_t order[MAX_LENGTH];
    for (size_t i = 0; i < n; ++i) order[i] = i;
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t position = i;
        while (position > 0 && rotation_less(values, n, key, order[position - 1])) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }

    size_t primary_index = 0;
    for (size_t row = 0; row < n; ++row) if (order[row] == 0) primary_index = row;
    const uint32_t encoded_index = (uint32_t)primary_index;
    for (size_t byte = 0; byte < 4; ++byte)
        output[byte] = (uint8_t)(encoded_index >> (8 * byte));
    for (size_t row = 0; row < n; ++row)
        output[4 + row] = (uint8_t)values[1 + (order[row] + n - 1) % n];
    return (int64_t)output_length;
}
