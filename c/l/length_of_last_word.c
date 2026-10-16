#include <stddef.h>
#include <stdint.h>

#define MAX_WORD_BYTES 128

int64_t length_of_last_word(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_WORD_BYTES + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_WORD_BYTES || length != (size_t)input[0] + 1) return -1;
    size_t index = (size_t)input[0];
    while (index > 0 && input[index] == 32) --index;
    int64_t word_length = 0;
    while (index > 0 && input[index] != 32) {
        if (input[index] < 0 || input[index] > 255) return -1;
        ++word_length;
        --index;
    }
    for (size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    return word_length;
}
