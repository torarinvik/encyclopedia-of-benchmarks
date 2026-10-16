#include <stddef.h>
#include <stdint.h>

#define MAX_STRINGS 16
#define MAX_STRING_LENGTH 64
#define MAX_TOTAL_CHARACTERS 512
#define MAX_INPUT_LENGTH (1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH))

int64_t common_characters_frequency_quotient(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    int64_t string_count = input[0];
    if (string_count < 0 || string_count > MAX_STRINGS) return -1;
    int64_t counts[26] = {0};
    size_t offset = 1, total = 0;
    for (int64_t string_index = 0; string_index < string_count; ++string_index) {
        if (offset >= length) return -1;
        int64_t string_length = input[offset++];
        if (string_length < 0 || string_length > MAX_STRING_LENGTH ||
            (size_t)string_length > length - offset) return -1;
        for (int64_t i = 0; i < string_length; ++i) {
            int64_t value = input[offset++];
            if (value < 'a' || value > 'z') return -1;
            ++counts[value - 'a'];
        }
        total += (size_t)string_length;
        if (total > MAX_TOTAL_CHARACTERS) return -1;
    }
    if (offset != length) return -1;

    size_t used = 0;
    if (string_count > 0)
        for (size_t letter = 0; letter < 26; ++letter)
            used += (size_t)(counts[letter] / string_count);
    if (used > capacity || (used > 0 && output == NULL)) return -2;
    size_t offset_output = 0;
    if (string_count > 0)
        for (size_t letter = 0; letter < 26; ++letter)
            for (int64_t copy = 0; copy < counts[letter] / string_count; ++copy)
                output[offset_output++] = (uint8_t)('a' + letter);
    return (int64_t)used;
}
