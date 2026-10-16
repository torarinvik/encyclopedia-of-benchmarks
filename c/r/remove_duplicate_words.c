#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4096
#define MAX_WORDS 2049

static int is_ascii_whitespace(int64_t byte) {
    return byte == 32 || (byte >= 9 && byte <= 13);
}

int64_t remove_duplicate_words(const int64_t *values, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_INPUT_LENGTH ||
        length != 1 + (size_t)values[0]) return -1;
    const size_t text_length = (size_t)values[0];
    for (size_t index = 0; index < text_length; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 127) return -1;

    size_t starts[MAX_WORDS], word_lengths[MAX_WORDS], word_count = 0;
    size_t token_start = 0, output_length = 0;
    for (size_t boundary = 0; boundary <= text_length; ++boundary) {
        if (boundary < text_length && !is_ascii_whitespace(values[boundary + 1])) continue;
        const size_t word_length = boundary - token_start;
        int duplicate = 0;
        for (size_t previous = 0; previous < word_count && !duplicate; ++previous) {
            if (word_lengths[previous] != word_length) continue;
            size_t offset = 0;
            while (offset < word_length &&
                   values[1 + starts[previous] + offset] == values[1 + token_start + offset]) ++offset;
            duplicate = offset == word_length;
        }
        if (!duplicate) {
            if (word_count == MAX_WORDS) return -1;
            starts[word_count] = token_start;
            word_lengths[word_count] = word_length;
            if (word_count > 0) ++output_length;
            output_length += word_length;
            ++word_count;
        }
        if (boundary < text_length) token_start = boundary + 1;
    }
    if (output_length > output_capacity || (output_length > 0 && output == NULL)) return -2;

    size_t written = 0;
    for (size_t word = 0; word < word_count; ++word) {
        if (word > 0) output[written++] = 32;
        for (size_t offset = 0; offset < word_lengths[word]; ++offset)
            output[written++] = (uint8_t)values[1 + starts[word] + offset];
    }
    return (int64_t)written;
}
