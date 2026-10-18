#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 16u
#define MAX_INPUT 18u
#define MAX_SYMBOLS 16u
#define MAX_CODE 15u
#define MAX_OUTPUT 514u

static int make_codes(const uint8_t *symbols, size_t count, const double freq[128],
                      uint8_t *prefix, size_t depth,
                      uint8_t codes[128][MAX_CODE], uint8_t lengths[128]) {
    if (count == 1u) {
        for (size_t i = 0; i < depth; ++i) codes[symbols[0]][i] = prefix[i];
        lengths[symbols[0]] = (uint8_t)depth;
        return 1;
    }
    double total = 0.0;
    for (size_t i = 0; i < count; ++i) total += freq[symbols[i]];
    const double capacity = 0.5 * total;
    double running = 0.0;
    uint8_t left[MAX_SYMBOLS], right[MAX_SYMBOLS];
    size_t nl = 0, nr = 0;
    for (size_t i = 0; i < count; ++i) {
        const uint8_t s = symbols[i];
        if (running + freq[s] <= capacity) { left[nl++] = s; running += freq[s]; }
        else right[nr++] = s;
    }
    if (nl == 0 || nr == 0 || depth >= MAX_CODE) return 0;
    prefix[depth] = (uint8_t)'0';
    if (!make_codes(left, nl, freq, prefix, depth + 1, codes, lengths)) return 0;
    prefix[depth] = (uint8_t)'1';
    return make_codes(right, nr, freq, prefix, depth + 1, codes, lengths);
}

int64_t shannon_fano_compressor(const int64_t *input, size_t input_length,
                                uint8_t *output, size_t capacity) {
    if (input_length > MAX_INPUT || (input == NULL ? input_length != 0u : input_length == 0u)) return -1;
    size_t text_len = 0;
    if (input != NULL) {
        if (input[0] < 0 || input[0] > (int64_t)MAX_TEXT) return -1;
        text_len = (size_t)input[0];
        if (input_length != text_len + 1u) return -1;
    }
    uint8_t text[MAX_TEXT], symbols[MAX_SYMBOLS], codes[128][MAX_CODE] = {{0}}, lengths[128] = {0};
    size_t counts[128] = {0}, symbol_count = 0;
    uint8_t seen[128] = {0};
    for (size_t i = 0; i < text_len; ++i) {
        int64_t v = input[i + 1];
        if (v < 0 || v > 127) return -1;
        text[i] = (uint8_t)v;
        if (!seen[text[i]]) { seen[text[i]] = 1; symbols[symbol_count++] = text[i]; }
        ++counts[text[i]];
    }
    double freq[128] = {0.0};
    if (text_len != 0) for (size_t s = 0; s < 128; ++s) freq[s] = (1.0 * (double)counts[s]) / (double)text_len;
    if (symbol_count == 1) {
        lengths[symbols[0]] = 1;
        codes[symbols[0]][0] = (uint8_t)'1';
    } else if (symbol_count > 1) {
        uint8_t prefix[MAX_CODE] = {0};
        if (!make_codes(symbols, symbol_count, freq, prefix, 0, codes, lengths)) return -1;
    }
    uint8_t staged[MAX_OUTPUT];
    size_t n = 0;
    size_t compressed_len = 0;
    for (size_t i = 0; i < text_len; ++i) compressed_len += lengths[text[i]];
    staged[n++] = (uint8_t)compressed_len;
    for (size_t i = 0; i < text_len; ++i)
        for (size_t j = 0; j < lengths[text[i]]; ++j) staged[n++] = codes[text[i]][j];
    staged[n++] = (uint8_t)symbol_count;
    for (size_t s = 0; s < 128; ++s) if (lengths[s] != 0) {
        staged[n++] = (uint8_t)s;
        staged[n++] = lengths[s];
        for (size_t j = 0; j < lengths[s]; ++j) staged[n++] = codes[s][j];
    }
    if (output == NULL || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = staged[i];
    return (int64_t)n;
}
