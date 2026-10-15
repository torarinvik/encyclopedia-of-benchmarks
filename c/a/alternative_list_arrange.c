#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 64

int64_t alternative_list_arrange(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_SIDE) return -1;
    size_t a = (size_t)input[0];
    if (1 + a >= length || input[1 + a] < 0 || input[1 + a] > MAX_SIDE) return -1;
    size_t b = (size_t)input[1 + a];
    if (length != 2 + a + b) return -1;
    size_t count = a + b;
    if (capacity < count * 8 || (count != 0 && output == NULL)) return -2;
    size_t out = 0;
    for (size_t i = 0; i < a || i < b; ++i) {
        if (i < a) { uint64_t v = (uint64_t)input[1 + i]; for (size_t j = 0; j < 8; ++j) output[out++] = (uint8_t)(v >> (8 * j)); }
        if (i < b) { uint64_t v = (uint64_t)input[2 + a + i]; for (size_t j = 0; j < 8; ++j) output[out++] = (uint8_t)(v >> (8 * j)); }
    }
    return (int64_t)count;
}
