/* Append two bounded printable ASCII strings. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 64

int64_t string_append(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2) return -1;
    const uint64_t first_length = (uint64_t)input[0];
    const uint64_t second_length = (uint64_t)input[1];
    if ((first_length > second_length ? first_length : second_length) > MAX_SIDE) return -1;
    const size_t count = length - 2;
    if (count != first_length + second_length) return -1;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[2 + i];
        if (value < 32 || value > 126) return -1;
    }
    if (capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = (uint8_t)input[2 + i];
    return (int64_t)count;
}
