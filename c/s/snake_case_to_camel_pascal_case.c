#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

int64_t snake_case_to_camel_pascal_case(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_LENGTH + 1) return -1;
    if (input[0] != 0 && input[0] != 1) return -1;

    size_t input_length = length - 1;
    size_t output_length = 0;
    for (size_t i = 0; i < input_length; ++i) {
        int64_t value = input[i + 1];
        if (value == '_') {
            if (i == 0 || i + 1 == input_length || input[i] == '_') return -1;
        } else if (!((value >= 'a' && value <= 'z') || (value >= '0' && value <= '9'))) {
            return -1;
        } else {
            ++output_length;
        }
    }
    if (capacity < output_length || output == NULL) return -2;

    size_t position = 0;
    int capitalize = input[0] == 1;
    for (size_t i = 0; i < input_length; ++i) {
        int64_t value = input[i + 1];
        if (value == '_') {
            capitalize = 1;
            continue;
        }
        if (capitalize && value >= 'a' && value <= 'z') value -= 'a' - 'A';
        output[position++] = (uint8_t)value;
        capitalize = 0;
    }
    return (int64_t)output_length;
}
