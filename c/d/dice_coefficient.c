#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 128
#define ALPHABET_SIZE 95
#define INVALID_RESULT (-1.0e300)

double dice_coefficient(const int64_t *values, size_t length) {
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t len_a_raw = values[0];
    const int64_t len_b_raw = values[1];
    if (len_a_raw < 0 || len_a_raw > MAX_STRING_LENGTH ||
        len_b_raw < 0 || len_b_raw > MAX_STRING_LENGTH) return INVALID_RESULT;
    const size_t len_a = (size_t)len_a_raw;
    const size_t len_b = (size_t)len_b_raw;
    if (length != 2 + len_a + len_b) return INVALID_RESULT;
    for (size_t i = 0; i < len_a + len_b; ++i) {
        const int64_t code = values[2 + i];
        if (code < 32 || code > 126) return INVALID_RESULT;
    }
    int equal = len_a == len_b;
    for (size_t i = 0; equal && i < len_a; ++i)
        equal = values[2 + i] == values[2 + len_a + i];
    if (equal) return 1.0;
    if (len_a < 2 || len_b < 2) return 0.0;

    uint8_t present[ALPHABET_SIZE][ALPHABET_SIZE] = {{0}};
    for (size_t i = 0; i + 1 < len_a; ++i) {
        const size_t first = (size_t)(values[2 + i] - 32);
        const size_t second = (size_t)(values[2 + i + 1] - 32);
        present[first][second] = 1;
    }
    size_t common = 0;
    for (size_t i = 0; i + 1 < len_b; ++i) {
        const size_t first = (size_t)(values[2 + len_a + i] - 32);
        const size_t second = (size_t)(values[2 + len_a + i + 1] - 32);
        if (present[first][second]) ++common;
    }
    const double denominator = (double)(len_a - 1 + len_b - 1);
    const double score = (2.0 * (double)common) / denominator;
    return floor(score * 100.0) / 100.0;
}
