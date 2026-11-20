#include <stddef.h>
#include <stdint.h>

enum { FREIVALDS_MAX_N = 8, FREIVALDS_MAX_ROUNDS = 8,
       FREIVALDS_MAX_INPUT = 258 + 1 };

int64_t freivalds_matrix_product_verification(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > FREIVALDS_MAX_INPUT) return -1;
    const int64_t n64 = input[0], rounds64 = input[1];
    if (n64 < 1 || n64 > FREIVALDS_MAX_N || rounds64 < 1 || rounds64 > FREIVALDS_MAX_ROUNDS) return -1;
    const size_t n = (size_t)n64, rounds = (size_t)rounds64;
    const size_t matrix_words = n * n;
    if (length != 2 + 3 * matrix_words + rounds * n) return -1;
    for (size_t word = 2; word < 2 + 3 * matrix_words; ++word)
        if (input[word] < -3 || input[word] > 3) return -1;
    const size_t signs_offset = 2 + 3 * matrix_words;
    for (size_t word = signs_offset; word < length; ++word)
        if (input[word] != -1 && input[word] != 1) return -1;

    int64_t bx[FREIVALDS_MAX_N], abx[FREIVALDS_MAX_N], cx[FREIVALDS_MAX_N];
    for (size_t round = 0; round < rounds; ++round) {
        for (size_t row = 0; row < n; ++row) {
            int64_t sum = 0;
            for (size_t col = 0; col < n; ++col)
                sum += input[2 + matrix_words + row * n + col]
                     * input[signs_offset + round * n + col];
            bx[row] = sum;
        }
        for (size_t row = 0; row < n; ++row) {
            int64_t left = 0, right = 0;
            for (size_t col = 0; col < n; ++col) {
                left += input[2 + row * n + col] * bx[col];
                right += input[2 + 2 * matrix_words + row * n + col]
                       * input[signs_offset + round * n + col];
            }
            abx[row] = left;
            cx[row] = right;
        }
        for (size_t row = 0; row < n; ++row)
            if (abx[row] != cx[row]) return 0;
    }
    return 1;
}
