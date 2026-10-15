/* Interleave two bounded ASCII strings, then append the longer suffix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 64

int64_t alternative_string_arrange(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_SIDE) return -1;
    const size_t first_length = (size_t)input[0];
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > MAX_SIDE) return -1;
    const size_t second_length = (size_t)input[1 + first_length];
    if (length != 2 + first_length + second_length) return -1;
    for (size_t i = 0; i < first_length; ++i) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    for (size_t i = 0; i < second_length; ++i) if (input[2 + first_length + i] < 0 || input[2 + first_length + i] > 127) return -1;
    const size_t count = first_length + second_length;
    if (capacity < count || (count != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t i = 0; i < first_length || i < second_length; ++i) {
        if (i < first_length) output[written++] = (uint8_t)input[1 + i];
        if (i < second_length) output[written++] = (uint8_t)input[2 + first_length + i];
    }
    return (int64_t)written;
}
