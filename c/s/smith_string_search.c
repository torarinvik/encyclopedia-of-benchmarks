/* Bounded all-occurrences Smith string search. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define SMITH_MAX_TEXT 255
#define SMITH_MAX_PATTERN 64
#define SMITH_MAX_FRAME 322
#define SMITH_ALPHABET 128

static void smith_store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t smith_string_search(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > SMITH_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > SMITH_MAX_TEXT ||
        input[1] < 1 || input[1] > SMITH_MAX_PATTERN) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    int64_t positions[SMITH_MAX_TEXT];
    size_t match_count = 0;
    if (m <= n) {
        const size_t pattern_start = 2 + n;
        size_t horspool[SMITH_ALPHABET];
        size_t quick_search[SMITH_ALPHABET];
        for (size_t byte = 0; byte < SMITH_ALPHABET; ++byte) {
            horspool[byte] = m;
            quick_search[byte] = m + 1;
        }
        for (size_t i = 0; i + 1 < m; ++i)
            horspool[(size_t)input[pattern_start + i]] = m - i - 1;
        for (size_t i = 0; i < m; ++i)
            quick_search[(size_t)input[pattern_start + i]] = m - i;

        size_t alignment = 0;
        const size_t last_alignment = n - m;
        while (alignment <= last_alignment) {
            bool matches = true;
            for (size_t i = 0; i < m; ++i) {
                if (input[pattern_start + i] != input[2 + alignment + i]) {
                    matches = false;
                    break;
                }
            }
            if (matches) positions[match_count++] = (int64_t)alignment;
            const size_t end_byte = (size_t)input[2 + alignment + m - 1];
            const size_t lookahead = alignment + m;
            const size_t quick_shift = lookahead < n
                ? quick_search[(size_t)input[2 + lookahead]] : m + 1;
            const size_t end_shift = horspool[end_byte];
            alignment += end_shift > quick_shift ? end_shift : quick_shift;
        }
    }

    const size_t output_bytes = match_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t i = 0; i < match_count; ++i)
        smith_store_i64_le(output, i * 8, positions[i]);
    return (int64_t)output_bytes;
}
