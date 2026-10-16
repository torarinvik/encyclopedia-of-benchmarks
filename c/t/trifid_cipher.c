/* Trifid cipher with a caller-supplied 27-symbol alphabet and block period. */
#include <stddef.h>
#include <stdint.h>

static const char *codes[27] = {
    "111","112","113","121","122","123","131","132","133",
    "211","212","213","221","222","223","231","232","233",
    "311","312","313","321","322","323","331","332","333"
};

static int upper_ascii(int c) { return c >= 'a' && c <= 'z' ? c - ('a' - 'A') : c; }

int64_t trifid_cipher(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (!input || length < 31) return -1;
    int64_t mode = input[0], period_value = input[1], n_value = input[2], a_value = input[3];
    if ((mode != 0 && mode != 1) || period_value < 1 || period_value > 256 ||
        n_value < 0 || n_value > 256 || a_value != 27 ||
        length != (size_t)(31 + n_value)) return -1;
    size_t period = (size_t)period_value, n = (size_t)n_value;
    uint8_t alphabet[27], text[256], result[256];
    size_t alen = 0, tlen = 0, rlen = 0;
    for (size_t i = 0; i < 27; ++i) {
        int64_t v = input[4 + n + i];
        if (v < 0 || v > 127) return -1;
        int c = upper_ascii((int)v);
        if (c == ' ') continue;
        for (size_t j = 0; j < alen; ++j) if (alphabet[j] == c) return -1;
        alphabet[alen++] = (uint8_t)c;
    }
    if (alen != 27) return -1;
    for (size_t i = 0; i < n; ++i) {
        int64_t v = input[4 + i];
        if (v < 0 || v > 127) return -1;
        int c = upper_ascii((int)v);
        if (c == ' ') continue;
        int found = 0;
        for (size_t j = 0; j < 27; ++j) if (alphabet[j] == c) found = 1;
        if (!found) return -1;
        text[tlen++] = (uint8_t)c;
    }
    for (size_t start = 0; start < tlen; start += period) {
        size_t k = tlen - start;
        if (k > period) k = period;
        uint8_t digits[768];
        if (mode == 0) {
            size_t m = 0;
            for (size_t axis = 0; axis < 3; ++axis)
                for (size_t i = 0; i < k; ++i) {
                    size_t index = 0;
                    while (alphabet[index] != text[start+i]) ++index;
                    digits[m++] = (uint8_t)codes[index][axis];
                }
            for (size_t i = 0; i < m; i += 3) {
                int index = -1;
                for (int j = 0; j < 27; ++j)
                    if (codes[j][0] == digits[i] && codes[j][1] == digits[i+1] && codes[j][2] == digits[i+2]) index = j;
                if (index < 0) return -1;
                result[rlen++] = alphabet[index];
            }
        } else {
            for (size_t i = 0; i < k; ++i) {
                size_t index = 0;
                while (alphabet[index] != text[start+i]) ++index;
                for (size_t d = 0; d < 3; ++d) digits[i*3+d] = (uint8_t)codes[index][d];
            }
            for (size_t i = 0; i < k; ++i) {
                int index = -1;
                for (int j = 0; j < 27; ++j)
                    if (codes[j][0] == digits[i] && codes[j][1] == digits[k+i] && codes[j][2] == digits[2*k+i]) index = j;
                if (index < 0) return -1;
                result[rlen++] = alphabet[index];
            }
        }
    }
    if (output_capacity < rlen) return -2;
    if (rlen && !output) return -1;
    for (size_t i = 0; i < rlen; ++i) output[i] = result[i];
    return (int64_t)rlen;
}
