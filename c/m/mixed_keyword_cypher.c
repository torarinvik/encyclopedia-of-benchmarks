#include <stddef.h>
#include <stdint.h>

#define MAX_KEYWORD_LENGTH 64
#define MAX_PLAINTEXT_LENGTH 512
#define MAX_INPUT_LENGTH (2 + MAX_KEYWORD_LENGTH + MAX_PLAINTEXT_LENGTH)

int64_t mixed_keyword_cypher(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t raw_keyword_length = input[0];
    if (raw_keyword_length < 1 || raw_keyword_length > MAX_KEYWORD_LENGTH) return -1;
    const size_t keyword_length = (size_t)raw_keyword_length;
    const size_t plaintext_length_index = 1 + keyword_length;
    if (plaintext_length_index >= length) return -1;

    const int64_t raw_plaintext_length = input[plaintext_length_index];
    if (raw_plaintext_length < 0 || raw_plaintext_length > MAX_PLAINTEXT_LENGTH) return -1;
    const size_t plaintext_length = (size_t)raw_plaintext_length;
    if (length != plaintext_length_index + 1 + plaintext_length) return -1;

    uint8_t unique_letters[26] = {0};
    uint8_t seen[26] = {0};
    size_t unique_count = 0;
    for (size_t index = 0; index < keyword_length; ++index) {
        const int64_t raw = input[1 + index];
        if (raw < 0 || raw > 127) return -1;
        int letter = (int)raw;
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' && letter <= 'Z') {
            const size_t alphabet_index = (size_t)(letter - 'A');
            if (!seen[alphabet_index]) {
                seen[alphabet_index] = 1;
                unique_letters[unique_count++] = (uint8_t)letter;
            }
        }
    }
    if (unique_count == 0) return -1;

    for (size_t index = 0; index < plaintext_length; ++index) {
        const int64_t raw = input[plaintext_length_index + 1 + index];
        if (raw < 0 || raw > 127) return -1;
    }

    uint8_t shifted[26];
    for (size_t index = 0; index < unique_count; ++index)
        shifted[index] = unique_letters[index];
    size_t shifted_count = unique_count;
    for (size_t index = 0; index < 26; ++index) {
        if (!seen[index]) shifted[shifted_count++] = (uint8_t)('A' + index);
    }

    uint8_t mapping[26];
    size_t alphabet_index = 0;
    for (size_t column = 0; column < unique_count; ++column) {
        for (size_t row_start = 0; row_start < 26; row_start += unique_count) {
            const size_t shifted_index = row_start + column;
            if (shifted_index >= 26) break;
            mapping[alphabet_index++] = shifted[shifted_index];
        }
    }

    uint8_t buffer[MAX_PLAINTEXT_LENGTH];
    for (size_t index = 0; index < plaintext_length; ++index) {
        int letter = (int)input[plaintext_length_index + 1 + index];
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' && letter <= 'Z')
            buffer[index] = mapping[(size_t)(letter - 'A')];
        else
            buffer[index] = (uint8_t)letter;
    }

    if (output == NULL || capacity < plaintext_length) return -2;
    for (size_t index = 0; index < plaintext_length; ++index) output[index] = buffer[index];
    return (int64_t)plaintext_length;
}
