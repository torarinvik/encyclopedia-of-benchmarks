/* Append two bounded printable ASCII strings. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 64

int64_t string_append(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_SIDE) return -1;
    const size_t first_length = (size_t)input[0];
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > MAX_SIDE) return -1;
    const size_t second_length = (size_t)input[1 + first_length];
    if (length != 2 + first_length + second_length) return -1;
    for (size_t i = 0; i < first_length; ++i) if (input[2 + i] < 32 || input[2 + i] > 126) return -1;
    for (size_t i = 0; i < second_length; ++i) if (input[2 + first_length + i] < 32 || input[2 + first_length + i] > 126) return -1;
    const size_t count = first_length + second_length;
    if (capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < first_length; ++i) output[i] = (uint8_t)input[2 + i];
    for (size_t i = 0; i < second_length; ++i) output[first_length + i] = (uint8_t)input[2 + first_length + i];
    return (int64_t)count;
}
