#include <stddef.h>
#include <stdint.h>

#define MAX_ORDER INT64_C(8)
#define MOD INT64_C(1000000007)
#define MAX_N INT64_C(1000000000000)
#define MAX_INPUT_WORDS 18

typedef struct { int64_t cell[8][8]; } Matrix;

static Matrix multiply(Matrix left, Matrix right, int64_t order) {
    Matrix result = {0};
    for (int64_t row = 0; row < order; ++row) {
        for (int64_t col = 0; col < order; ++col) {
            for (int64_t inner = 0; inner < order; ++inner) {
                result.cell[row][col] = (result.cell[row][col] +
                    (left.cell[row][inner] * right.cell[inner][col]) % MOD) % MOD;
            }
        }
    }
    return result;
}

static Matrix power(Matrix matrix, int64_t exponent, int64_t order) {
    if (exponent == 1) return matrix;
    if (exponent % 2 == 1) return multiply(matrix, power(matrix, exponent - 1, order), order);
    Matrix half = power(matrix, exponent / 2, order);
    return multiply(half, half, order);
}

int64_t matrix_exponentiation(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_WORDS) return -1;
    const int64_t order = input[0];
    if (order < 1 || order > MAX_ORDER || length != (size_t)(2 * order + 2)) return -1;
    for (int64_t i = 0; i < 2 * order; ++i)
        if (input[1 + i] < 0 || input[1 + i] >= MOD) return -1;
    const int64_t n = input[2 * order + 1];
    if (n < 0 || n > MAX_N) return -1;
    if (n == 0) return 0;
    if (n <= order) return input[n];

    Matrix transition = {0};
    for (int64_t i = 0; i + 1 < order; ++i) transition.cell[i][i + 1] = 1;
    for (int64_t col = 0; col < order; ++col) transition.cell[order - 1][col] = input[order + 1 + order - 1 - col];
    transition = power(transition, n - 1, order);
    int64_t result = 0;
    for (int64_t i = 0; i < order; ++i)
        result = (result + (transition.cell[0][i] * input[1 + i]) % MOD) % MOD;
    return result;
}
