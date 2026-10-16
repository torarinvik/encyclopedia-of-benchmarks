#include <stddef.h>
#include <stdint.h>

static int is_ascii_whitespace(int64_t value) {
    return value == 32 || (value >= 9 && value <= 13);
}

int64_t longest_word_in_sentence(const int64_t *values, size_t length,
                                 uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > 1024 ||
        length != 1 + (size_t)values[0]) return -1;
    const size_t text_length = (size_t)values[0];
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t byte = values[index + 1];
        if (!is_ascii_whitespace(byte) && (byte < 33 || byte > 126)) return -1;
    }

    size_t best_start = 0, best_length = 0, index = 0;
    while (index < text_length) {
        if (is_ascii_whitespace(values[index + 1])) {
            ++index;
            continue;
        }
        const size_t start = index;
        while (index < text_length && !is_ascii_whitespace(values[index + 1])) ++index;
        const size_t word_length = index - start;
        if (word_length > best_length) {
            best_start = start;
            best_length = word_length;
        }
    }
    if (best_length > output_capacity || (best_length > 0 && output == NULL)) return -2;
    for (size_t byte = 0; byte < best_length; ++byte)
        output[byte] = (uint8_t)values[1 + best_start + byte];
    return (int64_t)best_length;
}
