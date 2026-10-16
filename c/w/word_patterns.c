#include <stddef.h>
#include <stdint.h>

int64_t word_patterns(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > 256 || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    int first[128]; for (int i = 0; i < 128; ++i) first[i] = -1;
    size_t pos = 0; int next = 0;
    for (size_t i = 0; i < n; ++i) {
        int ch = (int)input[i + 1]; if (ch < 0 || ch > 127) return -1;
        if (ch >= 'a' && ch <= 'z') ch -= 32;
        if (first[ch] < 0) first[ch] = next++;
    }
    if (output == NULL || capacity < 4 * n + 1) return -2;
    for (size_t i = 0; i < n; ++i) {
        int ch = (int)input[i + 1]; if (ch >= 'a' && ch <= 'z') ch -= 32;
        if (i) output[pos++] = '.';
        int value = first[ch]; char digits[3]; int count = 0;
        do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value);
        while (count) output[pos++] = (uint8_t)digits[--count];
    }
    output[pos] = 0; return (int64_t)pos;
}
