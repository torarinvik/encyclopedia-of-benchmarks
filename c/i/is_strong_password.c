#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256

int64_t is_strong_password(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_TEXT_LENGTH + 2) return -1;
    const int64_t minimum = input[0];
    const int64_t text_length = input[1];
    if (minimum < 0 || minimum > MAX_TEXT_LENGTH
            || text_length < 0 || text_length > MAX_TEXT_LENGTH
            || length != (size_t)text_length + 2) return -1;

    int upper = 0, lower = 0, digit = 0, punctuation = 0;
    for (size_t i = 0; i < (size_t)text_length; ++i) {
        int64_t value = input[i + 2];
        if (value < 0 || value > 127) return -1;
        if (value >= 'A' && value <= 'Z') upper = 1;
        if (value >= 'a' && value <= 'z') lower = 1;
        if (value >= '0' && value <= '9') digit = 1;
        if ((value >= 33 && value <= 47) || (value >= 58 && value <= 64)
                || (value >= 91 && value <= 96) || (value >= 123 && value <= 126)) {
            punctuation = 1;
        }
    }
    return text_length >= minimum && upper && lower && digit && punctuation ? 1 : 0;
}
