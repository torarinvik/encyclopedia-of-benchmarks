#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4096

int64_t swap_case(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }
    if (length > capacity || (length != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = input[i];
        if (value >= 'A' && value <= 'Z') value += 32;
        else if (value >= 'a' && value <= 'z') value -= 32;
        output[i] = (uint8_t)value;
    }
    return (int64_t)length;
}
