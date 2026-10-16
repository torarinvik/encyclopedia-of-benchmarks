#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 512
#define MAX_INPUT_LENGTH (MAX_TEXT_LENGTH + 2)

int64_t remove_duplicate_from_string(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t text_length_value = input[0];
    if (text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH ||
        length != 1 + (size_t)text_length_value) return -1;
    const size_t text_length = (size_t)text_length_value;
    uint8_t result[MAX_TEXT_LENGTH];
    uint8_t seen[128] = {0};
    size_t result_length = 0;
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = input[index + 1];
        if (value < 0 || value > 127) return -1;
        if (!seen[value]) {
            seen[value] = 1;
            result[result_length++] = (uint8_t)value;
        }
    }
    if (output_capacity < result_length || (result_length != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = result[index];
    return (int64_t)result_length;
}
