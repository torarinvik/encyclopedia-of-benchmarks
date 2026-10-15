#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 1024

int64_t one_time_pad_cipher(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH) return -1;
    const int64_t mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return -1;
    if (output_capacity < count || (count > 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) {
        const int64_t data = input[2 + index], key = input[2 + count + index];
        if (data < 0 || data > 255 || key < 0 || key > 255) return -1;
        output[index] = (uint8_t)(data ^ key);
    }
    return (int64_t)count;
}
