#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 32, MAX_INPUT = 34, MAX_OUTPUT = 512 };

static int suffix_less(const int64_t *text, size_t n, size_t a, size_t b) {
    while (a < n && b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        ++a;
        ++b;
    }
    return a == n && b != n;
}

static size_t lcp(const int64_t *text, size_t n, int64_t source, size_t target) {
    if (source < 0) return 0;
    size_t length = 0, p = (size_t)source;
    while (target + length < n && text[p + length] == text[target + length]) ++length;
    return length;
}

static void put64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) {
        out[at + i] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t lz77_lpf_suffix_array(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    const int64_t *text = input + 1;
    size_t sa[MAX_TEXT], inverse[MAX_TEXT], stack[MAX_TEXT];
    int64_t previous[MAX_TEXT], following[MAX_TEXT];
    for (size_t i = 0; i < n; ++i) sa[i] = i;
    for (size_t i = 1; i < n; ++i) {
        size_t value = sa[i], j = i;
        while (j > 0 && suffix_less(text, n, value, sa[j - 1])) {
            sa[j] = sa[j - 1];
            --j;
        }
        sa[j] = value;
    }
    for (size_t rank = 0; rank < n; ++rank) inverse[sa[rank]] = rank;

    size_t top = 0;
    for (size_t rank = 0; rank < n; ++rank) {
        while (top > 0 && sa[stack[top - 1]] > sa[rank]) --top;
        previous[rank] = top > 0 ? (int64_t)stack[top - 1] : -1;
        stack[top++] = rank;
    }
    top = 0;
    for (size_t rank = n; rank > 0; --rank) {
        size_t r = rank - 1;
        while (top > 0 && sa[stack[top - 1]] > sa[r]) --top;
        following[r] = top > 0 ? (int64_t)stack[top - 1] : -1;
        stack[top++] = r;
    }

    uint8_t staged[MAX_OUTPUT] = {0};
    size_t pairs = 0, pos = 0;
    while (pos < n) {
        size_t rank = inverse[pos];
        int64_t psv = previous[rank] >= 0 ? (int64_t)sa[(size_t)previous[rank]] : -1;
        int64_t nsv = following[rank] >= 0 ? (int64_t)sa[(size_t)following[rank]] : -1;
        size_t lp = lcp(text, n, psv, pos), ln = lcp(text, n, nsv, pos);
        int64_t source = ln > lp ? nsv : psv;
        size_t match = ln > lp ? ln : lp;
        if (match == 0) source = -1;
        put64(staged, pairs * 16, source);
        put64(staged, pairs * 16 + 8, (int64_t)match);
        ++pairs;
        pos += match > 0 ? match : 1;
    }
    size_t bytes = pairs * 16;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
