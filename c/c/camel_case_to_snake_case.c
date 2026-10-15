#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

int64_t camel_case_to_snake_case(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (length == 0 || length > MAX_LENGTH || input == NULL) return -1;

    size_t output_length = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = input[i];
        if (value >= 'A' && value <= 'Z') {
            if (i > 0) ++output_length;
        } else if (value < 'a' || value > 'z') {
            return -1;
        }
        ++output_length;
    }
    if (capacity < output_length || output == NULL) return -2;

    size_t position = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = input[i];
        if (value >= 'A' && value <= 'Z') {
            if (i > 0) output[position++] = '_';
            output[position++] = (uint8_t)(value + ('a' - 'A'));
        } else {
            output[position++] = (uint8_t)value;
        }
    }
    return (int64_t)output_length;
}
