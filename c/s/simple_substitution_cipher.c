#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 284
#define MAX_TEXT 256

int64_t simple_substitution_cipher(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 28 || length > MAX_INPUT) return -1;
    const int64_t mode = input[0], n64 = input[27];
    if ((mode != 0 && mode != 1) || n64 < 0 || n64 > MAX_TEXT || length != 28 + (size_t)n64) return -1;
    int seen[26] = {0};
    for (size_t i = 0; i < 26; ++i) {
        const int64_t value = input[1 + i];
        if (value < 65 || value > 90 || seen[value - 65]) return -1;
        seen[value - 65] = 1;
    }
    const size_t n = (size_t)n64;
    for (size_t i = 0; i < n; ++i) if (input[28 + i] < 0 || input[28 + i] > 127) return -1;
    if (output == NULL || output_capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) {
        const int64_t ch = input[28 + i];
        const int lower = ch >= 'a' && ch <= 'z';
        const int upper = ch >= 'A' && ch <= 'Z';
        if (!lower && !upper) { output[i] = (uint8_t)ch; continue; }
        const int index = (int)(ch - (lower ? 'a' : 'A'));
        int mapped;
        if (mode == 0) mapped = (int)input[1 + index] - 'A';
        else {
            mapped = 0;
            while (mapped < 26 && input[1 + mapped] != 'A' + index) ++mapped;
        }
        output[i] = (uint8_t)((lower ? 'a' : 'A') + mapped);
    }
    return (int64_t)n;
}
