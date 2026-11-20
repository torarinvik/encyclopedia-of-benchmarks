/* Bounded normalized Padé coefficient solve over F_998244353. */
#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_INPUT_LENGTH 12
#define MAX_OUTPUT_BYTES 96

static int64_t mod_pow(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) {
        output[offset + i] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t pade_approximant_series_coefficients(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t p_value = input[0], q_value = input[1];
    if (q_value < 1 || p_value < q_value || p_value > 4 || q_value > 4 ||
        length != (size_t)(p_value + q_value + 3)) return -1;
    const size_t p = (size_t)p_value, q = (size_t)q_value;
    uint32_t coefficients[9] = {0};
    for (size_t i = 0; i <= p + q; ++i) {
        if (input[i + 2] < 0 || input[i + 2] >= MODULUS) return -1;
        coefficients[i] = (uint32_t)input[i + 2];
    }
    const size_t required = 8 * (p + q + 4);
    if (output == NULL || capacity < required) return -2;

    uint32_t matrix[4][5] = {{0}};
    for (size_t row = 0; row < q; ++row) {
        const size_t m = p + 1 + row;
        for (size_t col = 0; col < q; ++col)
            matrix[row][col] = coefficients[m - (col + 1)];
        matrix[row][q] = (uint32_t)((MODULUS - coefficients[m]) % MODULUS);
    }

    for (size_t col = 0; col < q; ++col) {
        size_t pivot = col;
        while (pivot < q && matrix[pivot][col] == 0) ++pivot;
        if (pivot == q) return -3;
        if (pivot != col) {
            for (size_t j = col; j <= q; ++j) {
                uint32_t temporary = matrix[col][j];
                matrix[col][j] = matrix[pivot][j];
                matrix[pivot][j] = temporary;
            }
        }
        const int64_t inverse = mod_pow(matrix[col][col], MODULUS - 2);
        for (size_t j = col; j <= q; ++j)
            matrix[col][j] = (uint32_t)((int64_t)matrix[col][j] * inverse % MODULUS);
        for (size_t row = 0; row < q; ++row) {
            if (row == col) continue;
            const uint32_t factor = matrix[row][col];
            if (factor == 0) continue;
            for (size_t j = col; j <= q; ++j) {
                const int64_t product = (int64_t)factor * matrix[col][j] % MODULUS;
                int64_t difference = (int64_t)matrix[row][j] - product;
                if (difference < 0) difference += MODULUS;
                matrix[row][j] = (uint32_t)difference;
            }
        }
    }

    store_i64_le(output, 0, p_value);
    store_i64_le(output, 8, q_value);
    size_t offset = 16;
    for (size_t m = 0; m <= p; ++m) {
        uint64_t value = coefficients[m];
        const size_t last = m < q ? m : q;
        for (size_t j = 1; j <= last; ++j)
            value = (value + (uint64_t)coefficients[m - j] * matrix[j - 1][q]) % MODULUS;
        store_i64_le(output, offset, (int64_t)value);
        offset += 8;
    }
    store_i64_le(output, offset, 1);
    offset += 8;
    for (size_t j = 0; j < q; ++j) {
        store_i64_le(output, offset, matrix[j][q]);
        offset += 8;
    }
    return (int64_t)required;
}
