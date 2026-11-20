#include <stddef.h>
#include <stdint.h>

static size_t multiset_count(size_t n, size_t r) {
    if (r == 0) return 1;
    if (n == 0) return 0;
    const size_t top = n + r - 1;
    size_t result = 1;
    for (size_t index = 1; index <= r; ++index) {
        result = result * (top - r + index) / index;
    }
    return result;
}

int64_t combinations_with_repetition_lexicographic(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2) return -1;
    if (input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 4) return -1;
    const size_t n = (size_t)input[0];
    const size_t r = (size_t)input[1];
    const size_t count = multiset_count(n, r);
    const size_t byte_count = 2 + count * r;
    if (output == NULL || capacity < byte_count) return -2;

    output[0] = (uint8_t)(count & 255);
    output[1] = (uint8_t)((count >> 8) & 255);
    uint8_t current[4] = {0};
    for (size_t ordinal = 0; ordinal < count; ++ordinal) {
        for (size_t position = 0; position < r; ++position) {
            output[2 + ordinal * r + position] = current[position];
        }
        if (ordinal + 1 == count || r == 0) continue;
        size_t position = r;
        while (current[position - 1] == n - 1) --position;
        --position;
        ++current[position];
        for (size_t suffix = position + 1; suffix < r; ++suffix) {
            current[suffix] = current[position];
        }
    }
    return (int64_t)byte_count;
}
