#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256
#define MAX_VALID_INPUT_LENGTH (28 + MAX_TEXT_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define MASK_63 UINT64_C(0x7fffffffffffffff)

int64_t mono_alphabetic(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t operation = input[0];
    const int64_t raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 1 || raw_text_length > MAX_TEXT_LENGTH) return -1;
    const size_t text_length = (size_t)raw_text_length;
    if (length != 28 + text_length) return -1;

    bool seen[26] = {false};
    uint8_t inverse[26];
    for (size_t i = 0; i < 26; ++i) {
        const int64_t value = input[2 + i];
        if (value < 'A' || value > 'Z') return -1;
        const size_t index = (size_t)(value - 'A');
        if (seen[index]) return -1;
        seen[index] = true;
        inverse[index] = (uint8_t)i;
    }
    for (size_t i = 0; i < text_length; ++i)
        if (input[28 + i] < 'A' || input[28 + i] > 'Z') return -1;

    uint64_t hash = FNV_OFFSET_BASIS;
    const uint64_t length_word = (uint64_t)text_length;
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ (uint8_t)(length_word >> (8 * byte))) * FNV_PRIME;
    for (size_t i = 0; i < text_length; ++i) {
        const size_t index = (size_t)(input[28 + i] - 'A');
        const uint8_t mapped = operation == 0
            ? (uint8_t)input[2 + index]
            : (uint8_t)('A' + inverse[index]);
        hash = (hash ^ mapped) * FNV_PRIME;
    }
    return (int64_t)(hash & MASK_63);
}
