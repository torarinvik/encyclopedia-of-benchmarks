#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

int64_t upper(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127 || input[i] == 9 || input[i] == 10 || input[i] == 11 || input[i] == 12 || input[i] == 13 || input[i] == 32) return -1;
    if (capacity < length || (length != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < length; ++i) output[i] = (uint8_t)input[i];
    for (size_t i = 0; i < length; ++i) if (output[i] >= 'a' && output[i] <= 'z') output[i] -= 32;
    return (int64_t)length;
}
