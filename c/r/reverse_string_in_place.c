/* Reverse a byte array by swapping inward from both ends. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t reverse_string_in_place(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > UINT8_MAX) return -1;
    if (output_capacity < length || (length != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < length; ++index) output[index] = (uint8_t)input[index];
    size_t left = 0, right = length;
    while (left < right) {
        --right;
        if (left >= right) break;
        const uint8_t temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        ++left;
    }
    return (int64_t)length;
}
