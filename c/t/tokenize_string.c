#include <stddef.h>
#include <stdint.h>

int64_t tokenize_string(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 130) return -1;
    if (input[0] < 0 || input[0] > 128 || length != 2 + (size_t)input[0]) return -1;
    const int64_t separator = input[1];
    if (separator != 44 && separator != 46 && separator != 58) return -1;
    size_t separator_count = 0;
    for (size_t i = 0; i < (size_t)input[0]; ++i) {
        const int64_t byte = input[i + 2];
        if (byte < 32 || byte > 126) return -1;
        if (byte == separator) ++separator_count;
    }
    if (separator_count > 18) return -1;
    const size_t output_length = (size_t)input[0] + 2;
    if (output == NULL || capacity < output_length) return -2;
    output[0] = (uint8_t)(separator_count + 1);
    for (size_t i = 0; i < (size_t)input[0]; ++i)
        output[i + 1] = input[i + 2] == separator ? 0 : (uint8_t)input[i + 2];
    output[output_length - 1] = 0;
    return (int64_t)output_length;
}
