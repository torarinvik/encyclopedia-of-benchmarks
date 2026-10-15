#include <stddef.h>
#include <stdint.h>

static int edge_space(int64_t v) { return (v >= 9 && v <= 13) || v == 32; }
static int digit(int64_t c) {
    if (c >= 'A' && c <= 'Z') return (int)(c - 'A');
    if (c >= 'a' && c <= 'z') return (int)(c - 'a' + 26);
    if (c >= '0' && c <= '9') return (int)(c - '0' + 52);
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}
int64_t base64_to_binary(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    size_t begin = 0, end = n;
    while (begin < end && edge_space(input[begin + 1])) ++begin;
    while (end > begin && edge_space(input[end])) --end;
    if (begin == end) return -1;
    int negative = input[begin + 1] == '-';
    if (negative) ++begin;
    size_t count = end - begin, out_len = count * 6 + (negative ? 1 : 0);
    for (size_t i = begin; i < end; ++i) if (digit(input[i + 1]) < 0) return -1;
    if (capacity < out_len || !output) return -2;
    size_t offset = 0;
    if (negative) output[offset++] = '-';
    for (size_t i = begin; i < end; ++i) {
        unsigned value = (unsigned)digit(input[i + 1]);
        for (int bit = 5; bit >= 0; --bit) output[offset++] = (uint8_t)('0' + ((value >> bit) & 1));
    }
    return (int64_t)out_len;
}
