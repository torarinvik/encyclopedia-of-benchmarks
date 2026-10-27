#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 32, MAX_INPUT = 36, ALPHABET = 5 };

static int suffix_less(const int64_t *text, size_t n, size_t a, size_t b) {
    while (a < n && b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        ++a;
        ++b;
    }
    return a == n && b != n;
}

int64_t fm_index_display(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0];
    if (n0 < 1 || n0 > MAX_TEXT || length != (size_t)n0 + 4) return -1;
    const size_t n = (size_t)n0;
    const int64_t left0 = input[n + 1], right0 = input[n + 2], stride0 = input[n + 3];
    if (left0 < 0 || right0 < left0 || right0 >= n0 || stride0 < 1 || stride0 > n0) return -1;
    const size_t left = (size_t)left0, right = (size_t)right0, stride = (size_t)stride0;
    const size_t size = n + 1;
    int64_t text[MAX_TEXT + 1];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 4) return -1;
        text[i] = input[i + 1];
    }
    text[n] = 0;

    size_t suffix_array[MAX_TEXT + 1];
    for (size_t i = 0; i < size; ++i) suffix_array[i] = i;
    for (size_t i = 1; i < size; ++i) {
        const size_t key = suffix_array[i];
        size_t j = i;
        while (j > 0 && suffix_less(text, size, key, suffix_array[j - 1])) {
            suffix_array[j] = suffix_array[j - 1];
            --j;
        }
        suffix_array[j] = key;
    }

    size_t inverse[MAX_TEXT + 1];
    int64_t bwt[MAX_TEXT + 1];
    size_t frequencies[ALPHABET] = {0};
    for (size_t row = 0; row < size; ++row) {
        const size_t pos = suffix_array[row];
        inverse[pos] = row;
        bwt[row] = text[(pos + size - 1) % size];
        ++frequencies[(size_t)bwt[row]];
    }
    size_t first[ALPHABET], total = 0;
    for (size_t c = 0; c < ALPHABET; ++c) {
        first[c] = total;
        total += frequencies[c];
    }
    size_t seen[ALPHABET] = {0}, lf[MAX_TEXT + 1];
    for (size_t row = 0; row < size; ++row) {
        const size_t c = (size_t)bwt[row];
        lf[row] = first[c] + seen[c]++;
    }

    size_t sampled_isa[MAX_TEXT + 1];
    uint8_t sampled[MAX_TEXT + 1] = {0};
    for (size_t pos = 0; pos < n; ++pos) if ((pos + 1) % stride == 0) {
        sampled[pos] = 1;
        sampled_isa[pos] = inverse[pos];
    }
    sampled[n] = 1;
    sampled_isa[n] = inverse[n];
    size_t sample = ((right + 1) / stride + 1) * stride - 1;
    if (sample > n) sample = n;
    if (!sampled[sample]) return -1;
    size_t row = sampled_isa[sample], current = sample;
    while (current > right + 1) {
        row = lf[row];
        --current;
    }
    uint8_t reversed[MAX_TEXT];
    size_t count = 0;
    while (current > left) {
        reversed[count++] = (uint8_t)bwt[row];
        row = lf[row];
        --current;
    }
    if (count != right - left + 1) return -1;
    if (output == NULL || capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = reversed[count - 1 - i];
    return (int64_t)count;
}
