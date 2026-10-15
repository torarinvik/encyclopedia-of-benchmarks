#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 256
static const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static int edge_space(int64_t value) { return (value >= 9 && value <= 13) || value == 32; }

int64_t binary_to_base64(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || input[0] < 1 || input[0] > MAX_INPUT) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    size_t begin = 0, end = n;
    while (begin < end && edge_space(input[1 + begin])) ++begin;
    while (end > begin && edge_space(input[end])) --end;
    if (begin == end) return -1;
    int negative = input[1 + begin] == '-';
    if (negative) ++begin;
    for (size_t i = begin; i < end; ++i) if (input[1 + i] != '0' && input[1 + i] != '1') return -1;
    size_t bit_count = end - begin;
    size_t padding = 6 - bit_count % 6;
    size_t groups = (bit_count + padding) / 6;
    size_t output_length = groups + (negative ? 1 : 0);
    if (capacity < output_length || output == NULL) return -2;
    size_t offset = 0;
    if (negative) output[offset++] = '-';
    for (size_t group = 0; group < groups; ++group) {
        unsigned value = 0;
        for (size_t bit = 0; bit < 6; ++bit) {
            value <<= 1;
            size_t position = group * 6 + bit;
            if (position >= padding && input[1 + begin + position - padding] == '1') ++value;
        }
        output[offset++] = (uint8_t)alphabet[value];
    }
    return (int64_t)output_length;
}
