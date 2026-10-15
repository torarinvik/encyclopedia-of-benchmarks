#include <stddef.h>
#include <stdint.h>

int64_t title_case_conversion(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if ((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) continue;
        if (value == ' ' && i > 0 && i + 1 < n && input[i] != ' ') continue;
        return -1;
    }
    if (output == NULL || capacity < n + 1) return -2;
    int at_word_start = 1;
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[i + 1];
        if (value == ' ') {
            output[i] = (uint8_t)value;
            at_word_start = 1;
        } else if (at_word_start) {
            if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
            output[i] = (uint8_t)value;
            at_word_start = 0;
        } else {
            if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
            output[i] = (uint8_t)value;
        }
    }
    output[n] = 0;
    return (int64_t)n;
}
