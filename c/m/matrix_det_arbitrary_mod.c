#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT_VALUES (2 + MAX_N * MAX_N + 1)
#define MAX_MODULUS INT64_C(1000000000)

static int64_t normalize(int64_t value, int64_t modulus) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t matrix_det_arbitrary_mod(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], modulus = input[1];
    if (n_value < 0 || n_value > MAX_N || modulus < 2 || modulus > MAX_MODULUS)
        return -1;
    const size_t n = (size_t)n_value;
    if (length != 2 + n * n) return -1;

    int64_t matrix[MAX_N][MAX_N] = {{0}};
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const int64_t value = input[2 + row * n + column];
            if (value < 0 || value >= modulus) return -1;
            matrix[row][column] = value;
        }
    }

    int64_t determinant = 1;
    int sign = 0;
    for (size_t column = 0; column < n; ++column) {
        size_t pivot = column;
        while (pivot < n && matrix[pivot][column] == 0) ++pivot;
        if (pivot == n) {
            determinant = 0;
            break;
        }
        if (pivot != column) {
            for (size_t k = 0; k < n; ++k) {
                const int64_t temporary = matrix[column][k];
                matrix[column][k] = matrix[pivot][k];
                matrix[pivot][k] = temporary;
            }
            sign ^= 1;
        }

        for (size_t row = column + 1; row < n; ++row) {
            int64_t left = matrix[column][column];
            int64_t right = matrix[row][column];
            if (right == 0) continue;
            int64_t a0 = 1, a1 = 0, b0 = 0, b1 = 1;
            while (left != 0 && right != 0) {
                if (left < right) {
                    const int64_t quotient = right / left;
                    right -= quotient * left;
                    b0 = normalize(b0 - a0 * quotient, modulus);
                    b1 = normalize(b1 - a1 * quotient, modulus);
                } else {
                    const int64_t quotient = left / right;
                    left -= quotient * right;
                    a0 = normalize(a0 - b0 * quotient, modulus);
                    a1 = normalize(a1 - b1 * quotient, modulus);
                }
            }
            for (size_t k = column; k < n; ++k) {
                const int64_t old_top = matrix[column][k];
                const int64_t old_bottom = matrix[row][k];
                matrix[column][k] = normalize(old_top * a0 + old_bottom * a1, modulus);
                matrix[row][k] = normalize(old_top * b0 + old_bottom * b1, modulus);
            }
            if (left == 0) {
                for (size_t k = 0; k < n; ++k) {
                    const int64_t temporary = matrix[column][k];
                    matrix[column][k] = matrix[row][k];
                    matrix[row][k] = temporary;
                }
                sign ^= 1;
            }
        }
        determinant = determinant * matrix[column][column] % modulus;
        if (determinant == 0) break;
    }
    if (sign != 0 && determinant != 0) determinant = modulus - determinant;

    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, determinant);
    return 8;
}
