#include <stddef.h>
#include <stdint.h>

#define MAX_TERMS 64
#define MAX_WORDS (1 + 2 * MAX_TERMS)

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t hofstadter_figure_figure_sequences(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length == 0 || length > 2) return -1;
    if (input[0] < 1 || input[0] > MAX_TERMS || length != 1) return -1;
    size_t n = (size_t)input[0];
    int64_t figure[MAX_TERMS] = {0}, space[MAX_TERMS] = {0};
    figure[0] = 1;
    space[0] = 2;
    int64_t candidate = 3;
    for (size_t i = 1; i < n; ++i) {
        figure[i] = figure[i - 1] + space[i - 1];
        for (;;) {
            int used = 0;
            for (size_t j = 0; j <= i; ++j) if (figure[j] == candidate) used = 1;
            if (!used) break;
            ++candidate;
        }
        space[i] = candidate++;
    }
    size_t count = 1 + 2 * n, bytes = count * 8;
    if (output == NULL || capacity < bytes) return -2;
    int64_t words[MAX_WORDS] = {0};
    words[0] = (int64_t)n;
    for (size_t i = 0; i < n; ++i) { words[1 + i] = figure[i]; words[1 + n + i] = space[i]; }
    for (size_t i = 0; i < count; ++i) write_i64_le(output, i * 8, words[i]);
    return (int64_t)bytes;
}
