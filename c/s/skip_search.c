#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227, ALPHABET = 4 };

int64_t skip_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != (size_t)(2 + n + m)) return -1;

    uint8_t text[MAX_TEXT], pattern[MAX_PATTERN];
    for (int q = 0; q < n; ++q) {
        const int64_t value = input[2 + q];
        if (value < 0 || value >= ALPHABET) return -1;
        text[q] = (uint8_t)value;
    }
    int positions[ALPHABET][MAX_PATTERN] = {{0}};
    int bucket_size[ALPHABET] = {0};
    for (int q = 0; q < m; ++q) {
        const int64_t value = input[2 + n + q];
        if (value < 0 || value >= ALPHABET) return -1;
        pattern[q] = (uint8_t)value;
        positions[pattern[q]][bucket_size[pattern[q]]++] = q;
    }

    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    for (int sample = m - 1; sample < n; sample += m) {
        const int *bucket = positions[text[sample]];
        for (int item = 0; item < bucket_size[text[sample]]; ++item) {
            const int start = sample - bucket[item];
            if (start < 0 || start > n - m) continue;
            int matched = 0;
            while (matched < m && text[start + matched] == pattern[matched]) ++matched;
            if (matched == m) {
                ++count;
                offset_sum += start;
                offset_xor ^= start;
            }
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
