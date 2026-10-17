#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 128
#define MAX_PARSEABLE_INPUT_LENGTH 183
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define MASK_63 UINT64_C(0x7fffffffffffffff)

int64_t mono_alphabetic_cipher(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t operation = input[0];
    const int64_t raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > MAX_TEXT_LENGTH) return -1;
    const size_t text_length = (size_t)raw_text_length;
    if (length != 54 + text_length) return -1;

    bool key_seen[26] = {false}, alphabet_seen[26] = {false};
    uint8_t key_inverse[26], alphabet_inverse[26];
    for (size_t i = 0; i < 26; ++i) {
        const int64_t key_value = input[2 + i], alphabet_value = input[28 + i];
        if (key_value < 'A' || key_value > 'Z' || alphabet_value < 'A' || alphabet_value > 'Z') return -1;
        const size_t key_index = (size_t)(key_value - 'A'), alphabet_index = (size_t)(alphabet_value - 'A');
        if (key_seen[key_index] || alphabet_seen[alphabet_index]) return -1;
        key_seen[key_index] = true; alphabet_seen[alphabet_index] = true;
        key_inverse[key_index] = (uint8_t)i; alphabet_inverse[alphabet_index] = (uint8_t)i;
    }
    size_t output_length = 0;
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[54 + i];
        if (value == ' ' || (value >= '0' && value <= '9') ||
            (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) {
            if (value < '0' || value > '9') ++output_length;
        } else return -1;
    }

    uint64_t hash = FNV_OFFSET_BASIS;
    const uint64_t length_word = (uint64_t)output_length;
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ (uint8_t)(length_word >> (8 * byte))) * FNV_PRIME;
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[54 + i];
        if (value >= '0' && value <= '9') continue;
        uint8_t mapped;
        if (value == ' ') mapped = (uint8_t)value;
        else {
            const bool lower = value >= 'a' && value <= 'z';
            const size_t letter = (size_t)(lower ? value - 'a' : value - 'A');
            const size_t index = operation == 0 ? alphabet_inverse[letter] : key_inverse[letter];
            const int64_t target = operation == 0 ? input[2 + index] : input[28 + index];
            mapped = (uint8_t)(lower ? target + ('a' - 'A') : target);
        }
        hash = (hash ^ mapped) * FNV_PRIME;
    }
    return (int64_t)(hash & MASK_63);
}
