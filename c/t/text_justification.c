#include <stddef.h>
#include <stdint.h>

#define MAX_WIDTH 64
#define MAX_TEXT_BYTES 512
#define MAX_WORDS 64
#define MAX_INPUT_LENGTH (2 + MAX_TEXT_BYTES + 1)
#define MAX_OUTPUT_BYTES (MAX_WORDS * MAX_WIDTH + MAX_WORDS)

int64_t text_justification(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t width_value = input[0];
    const int64_t text_length_value = input[1];
    if (width_value < 1 || width_value > MAX_WIDTH ||
        text_length_value < 0 || text_length_value > MAX_TEXT_BYTES ||
        length != 2 + (size_t)text_length_value) return -1;
    const size_t width = (size_t)width_value;
    const size_t text_length = (size_t)text_length_value;

    uint8_t text[MAX_TEXT_BYTES];
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = input[index + 2];
        if (value != 32 && (value < 33 || value > 126)) return -1;
        text[index] = (uint8_t)value;
    }

    size_t starts[MAX_WORDS], lengths[MAX_WORDS];
    size_t word_count = 0;
    for (size_t index = 0; index < text_length;) {
        while (index < text_length && text[index] == ' ') ++index;
        if (index == text_length) break;
        const size_t start = index;
        while (index < text_length && text[index] != ' ') ++index;
        const size_t word_length = index - start;
        if (word_count == MAX_WORDS || word_length > width) return -1;
        starts[word_count] = start;
        lengths[word_count] = word_length;
        ++word_count;
    }

    uint8_t result[MAX_OUTPUT_BYTES];
    size_t result_length = 0;
    size_t line_start = 0, line_end = 0, letters = 0;
    int first_line = 1;
    for (size_t word = 0; word < word_count; ++word) {
        if (letters + lengths[word] + (line_end - line_start) <= width) {
            letters += lengths[word];
            ++line_end;
            continue;
        }
        if (!first_line) result[result_length++] = '\n';
        first_line = 0;
        const size_t count = line_end - line_start;
        if (count == 1) {
            for (size_t i = 0; i < lengths[line_start]; ++i)
                result[result_length++] = text[starts[line_start] + i];
            for (size_t i = lengths[line_start]; i < width; ++i)
                result[result_length++] = ' ';
        } else {
            const size_t gaps = count - 1;
            const size_t spaces = width - letters;
            const size_t base = spaces / gaps;
            const size_t extra = spaces % gaps;
            for (size_t item = 0; item < count; ++item) {
                const size_t current = line_start + item;
                for (size_t i = 0; i < lengths[current]; ++i)
                    result[result_length++] = text[starts[current] + i];
                if (item + 1 < count) {
                    const size_t gap_spaces = base + (item < extra ? 1 : 0);
                    for (size_t i = 0; i < gap_spaces; ++i)
                        result[result_length++] = ' ';
                }
            }
        }
        line_start = word;
        line_end = word + 1;
        letters = lengths[word];
    }

    if (!first_line) result[result_length++] = '\n';
    for (size_t item = line_start; item < line_end; ++item) {
        if (item != line_start) result[result_length++] = ' ';
        for (size_t i = 0; i < lengths[item]; ++i)
            result[result_length++] = text[starts[item] + i];
    }
    const size_t trailing_spaces = width - letters - (line_end - line_start) + 1;
    for (size_t i = 0; i < trailing_spaces; ++i) result[result_length++] = ' ';

    if (output_capacity < result_length || (result_length != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = result[index];
    return (int64_t)result_length;
}
