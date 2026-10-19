/*
 * Modified derivative of MiBench office-stringsearch bmhsrch.c.
 * Original case-sensitive BMH implementation: public domain, Raymond Gardner, 7/92.
 * Adaptation: bounded printable-byte input and little-endian i64 result ABI.
 */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 128
#define MAX_PATTERN 32
#define MAX_INPUT (2 + MAX_TEXT + MAX_PATTERN)

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[i] = (uint8_t)(bits >> (8 * i));
}

int64_t mibench_office_stringsearch_bmh(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t text_len_value = input[0], pattern_len_value = input[1];
    if (text_len_value < 0 || text_len_value > MAX_TEXT ||
        pattern_len_value < 1 || pattern_len_value > MAX_PATTERN) return -1;
    size_t text_len = (size_t)text_len_value, pattern_len = (size_t)pattern_len_value;
    if (length != 2 + text_len + pattern_len) return -1;
    uint8_t text[MAX_TEXT], pattern[MAX_PATTERN];
    for (size_t i = 0; i < text_len + pattern_len; ++i) {
        int64_t value = input[2 + i];
        if (value < 32 || value > 126) return -1;
        if (i < text_len) text[i] = (uint8_t)value;
        else pattern[i - text_len] = (uint8_t)value;
    }

    size_t shift[256];
    for (size_t i = 0; i < 256; ++i) shift[i] = pattern_len;
    for (size_t i = 0; i + 1 < pattern_len; ++i)
        shift[pattern[i]] = pattern_len - i - 1;
    int64_t match = -1;
    if (pattern_len <= text_len) {
        size_t start = 0;
        while (start <= text_len - pattern_len) {
            size_t j = pattern_len;
            while (j > 0 && text[start + j - 1] == pattern[j - 1]) --j;
            if (j == 0) { match = (int64_t)start; break; }
            start += shift[text[start + pattern_len - 1]];
        }
    }
    if (output == NULL || output_capacity < 8) return -2;
    store_i64_le(output, match);
    return 8;
}
