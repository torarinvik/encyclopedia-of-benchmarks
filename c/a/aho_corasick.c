#include <stddef.h>
#include <stdint.h>

#define MAX_PATTERNS 16
#define MAX_PATTERN_LENGTH 32
#define MAX_TEXT_LENGTH 256
#define MAX_NODES (1 + MAX_PATTERNS * MAX_PATTERN_LENGTH)
#define ALPHABET 128

static int valid_input(const int64_t *input, size_t length, size_t *text_start, size_t *pattern_starts, size_t *pattern_count)
{
    if (input == NULL || length < 3 || input[0] < 1 || input[0] > MAX_PATTERNS || input[1] < 0 || input[1] > MAX_TEXT_LENGTH) return 0;
    *pattern_count = (size_t)input[0];
    if (length < 2 + *pattern_count) return 0;
    size_t total = 2 + *pattern_count;
    for (size_t p = 0; p < *pattern_count; ++p) {
        const int64_t size = input[2 + p];
        if (size < 1 || size > MAX_PATTERN_LENGTH || total + (size_t)size > length) return 0;
        pattern_starts[p] = total;
        total += (size_t)size;
        for (size_t i = 0; i < (size_t)size; ++i) if (input[pattern_starts[p] + i] < 1 || input[pattern_starts[p] + i] > 127) return 0;
        for (size_t q = 0; q < p; ++q) {
            if (input[2 + q] != size) continue;
            size_t i = 0;
            while (i < (size_t)size && input[pattern_starts[q] + i] == input[pattern_starts[p] + i]) ++i;
            if (i == (size_t)size) return 0;
        }
    }
    *text_start = total;
    if (total + (size_t)input[1] != length) return 0;
    for (size_t i = 0; i < (size_t)input[1]; ++i) if (input[total + i] < 1 || input[total + i] > 127) return 0;
    return 1;
}

int64_t aho_corasick(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    size_t pattern_starts[MAX_PATTERNS], text_start, pattern_count;
    if (!valid_input(input, length, &text_start, pattern_starts, &pattern_count)) return -1;
    const size_t output_size = pattern_count * 8;
    if (output_capacity < output_size || output == NULL) return -2;

    int next[MAX_NODES][ALPHABET];
    int failure[MAX_NODES], terminal[MAX_NODES], queue[MAX_NODES];
    for (size_t n = 0; n < MAX_NODES; ++n) {
        failure[n] = 0;
        terminal[n] = -1;
        for (size_t c = 0; c < ALPHABET; ++c) next[n][c] = -1;
    }
    size_t nodes = 1;
    for (size_t p = 0; p < pattern_count; ++p) {
        int state = 0;
        const size_t pattern_length = (size_t)input[2 + p];
        for (size_t i = 0; i < pattern_length; ++i) {
            const size_t ch = (size_t)input[pattern_starts[p] + i];
            if (next[state][ch] == -1) next[state][ch] = (int)nodes++;
            state = next[state][ch];
        }
        terminal[state] = (int)p;
    }

    size_t head = 0, tail = 0;
    for (size_t ch = 1; ch < ALPHABET; ++ch) if (next[0][ch] != -1) queue[tail++] = next[0][ch];
    while (head < tail) {
        const int state = queue[head++];
        for (size_t ch = 1; ch < ALPHABET; ++ch) {
            const int child = next[state][ch];
            if (child == -1) continue;
            int suffix = failure[state];
            while (suffix != 0 && next[suffix][ch] == -1) suffix = failure[suffix];
            if (next[suffix][ch] != -1) suffix = next[suffix][ch];
            failure[child] = suffix;
            queue[tail++] = child;
        }
    }

    int64_t counts[MAX_PATTERNS] = {0};
    int state = 0;
    const size_t text_length = (size_t)input[1];
    for (size_t i = 0; i < text_length; ++i) {
        const size_t ch = (size_t)input[text_start + i];
        while (state != 0 && next[state][ch] == -1) state = failure[state];
        if (next[state][ch] != -1) state = next[state][ch];
        for (int match = state; match != 0; match = failure[match]) if (terminal[match] >= 0) ++counts[terminal[match]];
    }
    for (size_t p = 0; p < pattern_count; ++p)
        for (size_t b = 0; b < 8; ++b) output[p * 8 + b] = (uint8_t)(((uint64_t)counts[p] >> (8 * b)) & 0xff);
    return (int64_t)output_size;
}
