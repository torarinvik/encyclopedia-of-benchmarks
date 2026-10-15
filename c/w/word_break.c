/* Bottom-up word segmentation over packed lowercase ASCII letter codes. */
#include <stddef.h>
#include <stdint.h>

int64_t word_break(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 1122) return -1;
    const int64_t text_length_value = values[0];
    const int64_t word_count_value = values[1];
    if (text_length_value < 0 || text_length_value > 64 ||
        word_count_value < 0 || word_count_value > 32) return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t word_count = (size_t)word_count_value;
    const size_t dictionary_start = 2 + text_length;
    if (length != dictionary_start + word_count * 33) return -1;

    for (size_t index = 0; index < text_length; ++index) {
        if (values[2 + index] < 1 || values[2 + index] > 26) return -1;
    }
    for (size_t word = 0; word < word_count; ++word) {
        const size_t slot = dictionary_start + word * 33;
        const int64_t word_length = values[slot];
        if (word_length < 1 || word_length > 32) return -1;
        for (size_t index = 0; index < 32; ++index) {
            const int64_t code = values[slot + 1 + index];
            if (index < (size_t)word_length) {
                if (code < 1 || code > 26) return -1;
            } else if (code != 0) {
                return -1;
            }
        }
    }

    uint8_t reachable[65] = {0};
    reachable[0] = 1;
    for (size_t start = 0; start < text_length; ++start) {
        if (!reachable[start]) continue;
        for (size_t word = 0; word < word_count; ++word) {
            const size_t slot = dictionary_start + word * 33;
            const size_t word_length = (size_t)values[slot];
            if (word_length > text_length - start) continue;
            size_t index = 0;
            while (index < word_length &&
                   values[2 + start + index] == values[slot + 1 + index]) {
                ++index;
            }
            if (index == word_length) reachable[start + word_length] = 1;
        }
    }
    return reachable[text_length] ? 1 : 0;
}
