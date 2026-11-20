#include <stddef.h>
#include <stdint.h>

#define MMWS_MAX_TEXT 64
#define MMWS_MAX_WORDS 16
#define MMWS_MAX_WORD_LENGTH 8
#define MMWS_MAX_INPUT_LENGTH (2 + MMWS_MAX_TEXT + MMWS_MAX_WORDS * (1 + MMWS_MAX_WORD_LENGTH))
#define MMWS_MAX_PARSEABLE_LENGTH (MMWS_MAX_INPUT_LENGTH + 1)

int64_t maximum_matching_word_segmentation(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MMWS_MAX_PARSEABLE_LENGTH) return -1;
    const int64_t text_length_value = input[0];
    const int64_t word_count_value = input[1];
    if (text_length_value < 0 || text_length_value > MMWS_MAX_TEXT
        || word_count_value < 0 || word_count_value > MMWS_MAX_WORDS) return -1;

    const size_t text_length = (size_t)text_length_value;
    const size_t word_count = (size_t)word_count_value;
    if (length < 2 + text_length) return -1;
    for (size_t position = 0; position < text_length; ++position)
        if (input[2 + position] < 97 || input[2 + position] > 122) return -1;

    size_t word_offsets[MMWS_MAX_WORDS];
    size_t word_lengths[MMWS_MAX_WORDS];
    size_t cursor = 2 + text_length;
    for (size_t word = 0; word < word_count; ++word) {
        if (cursor >= length) return -1;
        const int64_t word_length_value = input[cursor++];
        if (word_length_value < 1 || word_length_value > MMWS_MAX_WORD_LENGTH) return -1;
        const size_t word_length = (size_t)word_length_value;
        if (word_length > length - cursor) return -1;
        word_offsets[word] = cursor;
        word_lengths[word] = word_length;
        for (size_t offset = 0; offset < word_length; ++offset)
            if (input[cursor + offset] < 97 || input[cursor + offset] > 122) return -1;
        cursor += word_length;
    }
    if (cursor != length) return -1;

    uint8_t token_ids[MMWS_MAX_TEXT];
    size_t token_count = 0;
    size_t position = 0;
    while (position < text_length) {
        size_t best_length = 0;
        uint8_t best_id = 0;
        for (size_t word = 0; word < word_count; ++word) {
            const size_t word_length = word_lengths[word];
            if (word_length <= best_length || word_length > text_length - position) continue;
            size_t offset = 0;
            while (offset < word_length && input[word_offsets[word] + offset] == input[2 + position + offset])
                ++offset;
            if (offset == word_length) {
                best_length = word_length;
                best_id = (uint8_t)(word + 1);
            }
        }
        token_ids[token_count++] = best_id;
        position += best_length == 0 ? 1 : best_length;
    }

    const size_t output_length = token_count + 1;
    if (output == NULL || capacity < output_length) return -2;
    output[0] = (uint8_t)token_count;
    for (size_t token = 0; token < token_count; ++token) output[token + 1] = token_ids[token];
    return (int64_t)output_length;
}
