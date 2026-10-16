#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t v[4]; } matrix2;

static void store_i64_le(int64_t value, uint8_t *output, size_t offset) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}
static matrix2 multiply(matrix2 a, matrix2 b) {
    matrix2 c = {{0, 0, 0, 0}};
    for (size_t r = 0; r < 2; ++r) for (size_t col = 0; col < 2; ++col)
        for (size_t k = 0; k < 2; ++k) c.v[r * 2 + col] += a.v[r * 2 + k] * b.v[k * 2 + col];
    return c;
}
static matrix2 power(matrix2 a, int64_t e) {
    if (e == 0) return (matrix2){{1, 0, 0, 1}};
    if (e & 1) return multiply(power(a, e - 1), a);
    matrix2 half = power(a, e / 2);
    return multiply(half, half);
}
int64_t matrix_exponentiation_recursive(const int64_t *input, size_t length, uint8_t *output, size_t cap) {
    if (!input || length != 5 || input[0] < 0 || input[0] > 30) return -2;
    for (size_t i = 1; i < 5; ++i) if (input[i] < -1 || input[i] > 1) return -2;
    if (!output || cap < 32) return -3;
    matrix2 a = {{input[1], input[2], input[3], input[4]}};
    matrix2 result = power(a, input[0]);
    for (size_t i = 0; i < 4; ++i) store_i64_le(result.v[i], output, i * 8);
    return 4;
}
