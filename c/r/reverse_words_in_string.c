#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_TEXT_LENGTH + 2)

static int is_trim_byte(int64_t value) { return value >= 0 && value <= 32; }
static int is_split_space(int64_t value) {
    return value == 32 || (value >= 9 && value <= 13);
}

int64_t reverse_words_in_string(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH || length != (size_t)input[0] + 1) return -1;
    const size_t text_length = (size_t)input[0];
    for (size_t i = 0; i < text_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    size_t start = 0, end = text_length;
    while (start < end && is_trim_byte(input[start + 1])) ++start;
    while (end > start && is_trim_byte(input[end])) --end;

    size_t output_length = 0, word_count = 0, position = start;
    while (position < end) {
        while (position < end && is_split_space(input[position + 1])) ++position;
        if (position == end) break;
        const size_t token_start = position;
        while (position < end && !is_split_space(input[position + 1])) ++position;
        output_length += position - token_start;
        if (word_count > 0) ++output_length;
        ++word_count;
    }
    if (capacity < output_length || (output_length > 0 && output == NULL)) return -2;

    size_t written = 0, emitted = 0;
    position = end;
    while (position > start) {
        while (position > start && is_split_space(input[position])) --position;
        if (position == start) break;
        const size_t token_end = position;
        while (position > start && !is_split_space(input[position])) --position;
        const size_t token_start = position;
        if (emitted > 0) output[written++] = ' ';
        for (size_t i = token_start; i < token_end; ++i) output[written++] = (uint8_t)input[i + 1];
        ++emitted;
    }
    return (int64_t)written;
}
