/* All-occurrences Turbo Boyer–Moore search over bounded ASCII byte strings. */
#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#define TB_MAX_TEXT 255
#define TB_MAX_PATTERN 64
#define TB_MAX_FRAME 322
#define TB_ALPHABET 128

static void tb_store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static void tb_good_suffix(const int64_t *pattern, size_t length, size_t *shift)
{
    size_t suffix[TB_MAX_PATTERN] = {0};
    suffix[length - 1] = length;
    ptrdiff_t g = (ptrdiff_t)length - 1;
    ptrdiff_t f = 0;
    for (ptrdiff_t index = (ptrdiff_t)length - 2; index >= 0; --index) {
        if (index > g && suffix[(size_t)(index + (ptrdiff_t)length - 1 - f)] < (size_t)(index - g)) {
            suffix[(size_t)index] = suffix[(size_t)(index + (ptrdiff_t)length - 1 - f)];
        } else {
            if (index < g) g = index;
            f = index;
            while (g >= 0 && pattern[(size_t)g] == pattern[(size_t)(g + (ptrdiff_t)length - 1 - f)]) --g;
            suffix[(size_t)index] = (size_t)(f - g);
        }
    }
    for (size_t index = 0; index < length; ++index) shift[index] = length;
    size_t border = 0;
    for (ptrdiff_t index = (ptrdiff_t)length - 1; index >= 0; --index) {
        if (suffix[(size_t)index] == (size_t)index + 1) {
            while (border < length - 1 - (size_t)index) {
                if (shift[border] == length) shift[border] = length - 1 - (size_t)index;
                ++border;
            }
        }
    }
    for (size_t index = 0; index + 1 < length; ++index)
        shift[length - 1 - suffix[index]] = length - 1 - index;
}

int64_t turbo_boyer_moore_search(const int64_t *input, size_t length,
                                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > TB_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > TB_MAX_TEXT ||
        input[1] < 1 || input[1] > TB_MAX_PATTERN) return -1;
    const size_t text_length = (size_t)input[0];
    const size_t pattern_length = (size_t)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (input[2 + index] < 0 || input[2 + index] >= TB_ALPHABET) return -1;

    const int64_t *text = input + 2;
    const int64_t *pattern = text + text_length;
    int64_t positions[TB_MAX_TEXT];
    size_t match_count = 0;
    if (pattern_length <= text_length) {
        size_t bad_character[TB_ALPHABET];
        size_t good_suffix[TB_MAX_PATTERN];
        for (size_t byte = 0; byte < TB_ALPHABET; ++byte) bad_character[byte] = pattern_length;
        for (size_t index = 0; index + 1 < pattern_length; ++index)
            bad_character[(size_t)pattern[index]] = pattern_length - index - 1;
        tb_good_suffix(pattern, pattern_length, good_suffix);

        size_t alignment = 0;
        size_t remembered = 0;
        size_t shift = pattern_length;
        while (alignment <= text_length - pattern_length) {
            ptrdiff_t index = (ptrdiff_t)pattern_length - 1;
            while (index >= 0 && pattern[(size_t)index] == text[alignment + (size_t)index]) {
                --index;
                if (remembered != 0 && index == (ptrdiff_t)pattern_length - 1 - (ptrdiff_t)shift)
                    index -= (ptrdiff_t)remembered;
            }
            if (index < 0) {
                positions[match_count++] = (int64_t)alignment;
                shift = good_suffix[0];
                remembered = pattern_length - shift;
            } else {
                const size_t matched_suffix = pattern_length - 1 - (size_t)index;
                const ptrdiff_t turbo_shift = (ptrdiff_t)remembered - (ptrdiff_t)matched_suffix;
                const ptrdiff_t bad_shift = (ptrdiff_t)bad_character[(size_t)text[alignment + (size_t)index]]
                    - (ptrdiff_t)pattern_length + 1 + index;
                const size_t gs = good_suffix[(size_t)index];
                ptrdiff_t chosen = turbo_shift;
                if (bad_shift > chosen) chosen = bad_shift;
                if ((ptrdiff_t)gs > chosen) chosen = (ptrdiff_t)gs;
                shift = (size_t)chosen;
                if (shift == gs) {
                    remembered = pattern_length - shift < matched_suffix
                        ? pattern_length - shift : matched_suffix;
                } else {
                    if (turbo_shift < bad_shift && shift < remembered + 1) shift = remembered + 1;
                    remembered = 0;
                }
            }
            alignment += shift;
        }
    }

    const size_t output_bytes = match_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < match_count; ++index)
        tb_store_i64_le(output, index * 8, positions[index]);
    return (int64_t)output_bytes;
}
