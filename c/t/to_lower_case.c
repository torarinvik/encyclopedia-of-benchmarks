/* Lowercase ASCII bytes without locale-dependent character handling. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t to_lower_case(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (size_t index = 0; index < length; ++index) {
        int64_t value = input[index];
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        output[index] = (uint8_t)value;
    }
    return (int64_t)length;
}
