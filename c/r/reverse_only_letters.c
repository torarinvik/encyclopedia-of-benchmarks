/* Reverse ASCII letters while leaving every other printable byte in place. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static int is_ascii_letter(uint8_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

int64_t reverse_only_letters(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 32 || input[index] > 126) return -1;
    if (output_capacity < length || (length != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < length; ++index) output[index] = (uint8_t)input[index];

    size_t left = 0, right = length;
    while (left < right) {
        if (!is_ascii_letter(output[left])) {
            ++left;
        } else if (!is_ascii_letter(output[right - 1])) {
            --right;
        } else {
            const uint8_t temporary = output[left];
            output[left] = output[right - 1];
            output[right - 1] = temporary;
            ++left;
            --right;
        }
    }
    return (int64_t)length;
}
