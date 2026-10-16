#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 512
#define MAX_INPUT_LENGTH (MAX_TEXT_LENGTH + 2)

static uint8_t lower_ascii(uint8_t value)
{
    return value >= 'A' && value <= 'Z' ? (uint8_t)(value + ('a' - 'A')) : value;
}

int64_t max_word(const int64_t *input, size_t length,
                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t text_length_value = input[0];
    if (text_length_value < 1 || text_length_value > MAX_TEXT_LENGTH ||
        length != 1 + (size_t)text_length_value) return -1;
    const size_t text_length = (size_t)text_length_value;
    uint8_t text[MAX_TEXT_LENGTH];
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[i + 1];
        const int is_letter = (value >= 65 && value <= 90) || (value >= 97 && value <= 122);
        if (value == ' ') {
            if (i == 0 || i + 1 == text_length || text[i - 1] == ' ') return -1;
        } else if (!is_letter || value == 'I') {
            return -1;
        }
        text[i] = (uint8_t)value;
    }

    size_t starts[MAX_TEXT_LENGTH], lengths[MAX_TEXT_LENGTH], counts[MAX_TEXT_LENGTH];
    size_t unique_count = 0;
    size_t start = 0;
    while (start < text_length) {
        size_t end = start;
        while (end < text_length && text[end] != ' ') ++end;
        const size_t word_length = end - start;
        if (word_length > 6) return -1;
        size_t found = unique_count;
        for (size_t key = 0; key < unique_count; ++key) {
            if (lengths[key] != word_length) continue;
            size_t offset = 0;
            while (offset < word_length &&
                   lower_ascii(text[starts[key] + offset]) == lower_ascii(text[start + offset])) {
                ++offset;
            }
            if (offset == word_length) { found = key; break; }
        }
        if (found == unique_count) {
            starts[unique_count] = start;
            lengths[unique_count] = word_length;
            counts[unique_count] = 1;
            ++unique_count;
        } else {
            ++counts[found];
        }
        start = end + 1;
    }

    size_t winner = 0;
    for (size_t key = 1; key < unique_count; ++key)
        if (counts[key] > counts[winner]) winner = key;
    const size_t result_length = lengths[winner];
    if (output_capacity < result_length || output == NULL) return -2;
    const int single_word = unique_count == 1 && counts[0] == 1;
    for (size_t i = 0; i < result_length; ++i) {
        const uint8_t value = text[starts[winner] + i];
        output[i] = single_word ? value : lower_ascii(value);
    }
    return (int64_t)result_length;
}
