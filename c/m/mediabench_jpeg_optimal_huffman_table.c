#include <stddef.h>
#include <stdint.h>

enum { MAX_SYMBOLS = 20, MAX_INPUT_LENGTH = 41, MAX_CLEN = 32 };

/* Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt. */
int64_t mediabench_jpeg_optimal_huffman_table(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_SYMBOLS) return -1;
    const int count = (int)input[0];
    if (length != (size_t)(1 + 2 * count)) return -1;
    for (int i = 0; i < count; ++i) {
        const int64_t symbol = input[1 + 2 * i], frequency = input[2 + 2 * i];
        if (symbol < 0 || symbol > 255 || frequency < 1 || frequency > 1000000) return -1;
        for (int j = 0; j < i; ++j) if (input[1 + 2 * j] == symbol) return -1;
    }
    const size_t output_size = (size_t)(17 + count);
    if (output == NULL || capacity < output_size) return -2;

    int64_t freq[257] = {0};
    int codesize[257] = {0};
    int others[257];
    int bits[MAX_CLEN + 1] = {0};
    for (int i = 0; i < 257; ++i) others[i] = -1;
    for (int i = 0; i < count; ++i) freq[input[1 + 2 * i]] = input[2 + 2 * i];
    freq[256] = 1;

    for (;;) {
        int c1 = -1, c2 = -1;
        int64_t value = 1000000000;
        for (int i = 0; i <= 256; ++i)
            if (freq[i] != 0 && freq[i] <= value) { value = freq[i]; c1 = i; }
        value = 1000000000;
        for (int i = 0; i <= 256; ++i)
            if (freq[i] != 0 && freq[i] <= value && i != c1) { value = freq[i]; c2 = i; }
        if (c2 < 0) break;
        freq[c1] += freq[c2]; freq[c2] = 0;
        ++codesize[c1]; while (others[c1] >= 0) { c1 = others[c1]; ++codesize[c1]; }
        others[c1] = c2;
        ++codesize[c2]; while (others[c2] >= 0) { c2 = others[c2]; ++codesize[c2]; }
    }
    for (int i = 0; i <= 256; ++i) if (codesize[i] != 0) {
        if (codesize[i] > MAX_CLEN) return -1;
        ++bits[codesize[i]];
    }
    for (int i = MAX_CLEN; i > 16; --i) {
        while (bits[i] > 0) {
            int j = i - 2;
            while (j >= 0 && bits[j] == 0) --j;
            if (j < 0 || bits[i] < 2) return -1;
            bits[i] -= 2; ++bits[i - 1]; bits[j + 1] += 2; --bits[j];
        }
    }
    int longest = 16;
    while (longest > 0 && bits[longest] == 0) --longest;
    if (longest == 0) return -1;
    --bits[longest]; /* Exclude the all-ones-reserving pseudo-symbol. */

    int symbol_count = 0;
    for (int size = 1; size <= MAX_CLEN; ++size)
        for (int symbol = 0; symbol <= 255; ++symbol)
            if (codesize[symbol] == size) ++symbol_count;
    if (symbol_count != count) return -1;

    output[0] = (uint8_t)count;
    for (int i = 1; i <= 16; ++i) output[i] = (uint8_t)bits[i];
    int out = 17;
    for (int size = 1; size <= MAX_CLEN; ++size)
        for (int symbol = 0; symbol <= 255; ++symbol)
            if (codesize[symbol] == size) output[out++] = (uint8_t)symbol;
    return out == (int)output_size ? (int64_t)output_size : -1;
}
