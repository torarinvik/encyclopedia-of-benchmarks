#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_N 8
#define MAX_INPUT_VALUES (1 + MAX_N * MAX_N + 1)
#define MAX_OUTPUT_BYTES (8 * (MAX_N + 1))

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t multiply(int64_t left, int64_t right) {
    return (left * right) % MODULUS;
}

static int64_t power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t characteristic_polynomial(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + n * n) return -1;

    int64_t matrix[MAX_N][MAX_N] = {{0}};
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const int64_t value = input[1 + row * n + column];
            if (value < 0 || value >= MODULUS) return -1;
            matrix[row][column] = value;
        }
    }

    for (size_t column = 0; column + 2 < n; ++column) {
        size_t pivot = column + 1;
        while (pivot < n && matrix[pivot][column] == 0) ++pivot;
        if (pivot == n) continue;
        if (pivot != column + 1) {
            for (size_t k = 0; k < n; ++k) {
                const int64_t value = matrix[column + 1][k];
                matrix[column + 1][k] = matrix[pivot][k];
                matrix[pivot][k] = value;
            }
            for (size_t k = 0; k < n; ++k) {
                const int64_t value = matrix[k][column + 1];
                matrix[k][column + 1] = matrix[k][pivot];
                matrix[k][pivot] = value;
            }
        }
        const int64_t inverse = power(matrix[column + 1][column], MODULUS - 2);
        for (size_t row = column + 2; row < n; ++row) {
            if (matrix[row][column] == 0) continue;
            const int64_t factor = multiply(matrix[row][column], inverse);
            for (size_t k = 0; k < n; ++k)
                matrix[row][k] = normalize(
                    matrix[row][k] - multiply(factor, matrix[column + 1][k]));
            for (size_t k = 0; k < n; ++k)
                matrix[k][column + 1] = normalize(
                    matrix[k][column + 1] + multiply(factor, matrix[k][row]));
        }
    }

    int64_t coefficients[MAX_N + 1][MAX_N + 1] = {{0}};
    coefficients[0][0] = 1;
    for (size_t size = 1; size <= n; ++size) {
        for (size_t degree = 0; degree <= size; ++degree) {
            int64_t value = degree == 0 ? 0 : coefficients[size - 1][degree - 1];
            if (degree < size)
                value -= multiply(matrix[size - 1][size - 1],
                                  coefficients[size - 1][degree]);
            coefficients[size][degree] = normalize(value);
        }
        int64_t subdiagonal_product = 1;
        for (int start = (int)size - 2; start >= 0; --start) {
            subdiagonal_product = multiply(
                subdiagonal_product, matrix[start + 1][start]);
            const int64_t term = multiply(
                subdiagonal_product, matrix[start][size - 1]);
            for (int degree = 0; degree <= start; ++degree)
                coefficients[size][degree] = normalize(
                    coefficients[size][degree] -
                    multiply(term, coefficients[start][degree]));
        }
    }

    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t degree = 0; degree <= n; ++degree)
        store_i64_le(output + 8 * degree, coefficients[n][degree]);
    return (int64_t)output_bytes;
}
