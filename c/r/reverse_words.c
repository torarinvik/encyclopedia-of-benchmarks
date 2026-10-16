#include <stddef.h>
#include <stdint.h>

int64_t reverse_words(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > 256 || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) {
        int64_t b = input[i + 1];
        if (!(b == 32 || (b >= 33 && b <= 126))) return -1;
        if (b == 32 && (i == 0 || i + 1 == n || input[i] == 32)) return -1;
    }
    if (capacity < n + 1 || output == NULL) return -2;
    size_t written = 0, end = n;
    while (end > 0) {
        size_t start = end;
        while (start > 0 && input[start] != 32) --start;
        size_t word_start = start;
        for (size_t i = word_start; i < end; ++i) output[written++] = (uint8_t)input[i + 1];
        if (word_start == 0) break;
        output[written++] = 32;
        end = start - 1;
    }
    output[written] = 0;
    return (int64_t)written;
}
