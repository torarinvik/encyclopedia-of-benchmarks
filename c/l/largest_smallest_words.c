#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 512
#define MAX_INPUT_LENGTH (MAX_TEXT_LENGTH + 3)
#define MAX_OUTPUT_BYTES (2 * MAX_TEXT_LENGTH + 8)

static int is_stripped_punctuation(uint8_t value)
{
    return value == '.' || value == ',' || value == '!' || value == '?' || value == '(' ||
           value == ')' || value == '[' || value == ']' || value == '{' || value == '}';
}

static void put_u32(uint8_t *output, size_t offset, uint32_t value)
{
    output[offset] = (uint8_t)value;
    output[offset + 1] = (uint8_t)(value >> 8);
    output[offset + 2] = (uint8_t)(value >> 16);
    output[offset + 3] = (uint8_t)(value >> 24);
}

int64_t largest_smallest_words(const int64_t *input, size_t length,
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
        if (value < 32 || value > 126) return -1;
        text[i] = (uint8_t)value;
    }

    size_t smallest_start = 0, largest_start = 0;
    size_t smallest_length = MAX_TEXT_LENGTH + 1, largest_length = 0, word_count = 0;
    for (size_t pos = 0; pos < text_length;) {
        while (pos < text_length && text[pos] == ' ') ++pos;
        if (pos == text_length) break;
        const size_t token_start = pos;
        while (pos < text_length && text[pos] != ' ') ++pos;
        size_t start = token_start, end = pos;
        while (start < end && is_stripped_punctuation(text[start])) ++start;
        while (end > start && is_stripped_punctuation(text[end - 1])) --end;
        const size_t word_length = end - start;
        if (word_length < smallest_length) { smallest_start = start; smallest_length = word_length; }
        if (word_length > largest_length) { largest_start = start; largest_length = word_length; }
        ++word_count;
    }
    if (word_count == 0) return -1;
    const size_t output_length = 8 + smallest_length + largest_length;
    if (output_capacity < output_length || output == NULL) return -2;
    put_u32(output, 0, (uint32_t)smallest_length);
    for (size_t i = 0; i < smallest_length; ++i) output[4 + i] = text[smallest_start + i];
    const size_t largest_header = 4 + smallest_length;
    put_u32(output, largest_header, (uint32_t)largest_length);
    for (size_t i = 0; i < largest_length; ++i)
        output[largest_header + 4 + i] = text[largest_start + i];
    return (int64_t)output_length;
}
