#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64

int64_t ones_complement(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (length == 0 || length > MAX_INPUT_LENGTH || input == NULL) return -1;
    for (size_t i = 0; i < length; ++i)
        if (input[i] != 48 && input[i] != 49) return -1;
    if (length > capacity || output == NULL) return -2;
    for (size_t i = 0; i < length; ++i)
        output[i] = (uint8_t)(input[i] == 48 ? 49 : 48);
    return (int64_t)length;
}
