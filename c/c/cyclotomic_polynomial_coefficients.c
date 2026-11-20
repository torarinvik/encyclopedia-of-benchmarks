#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_INPUT_LENGTH 2

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static void build_through(int64_t polynomials[MAX_N + 1][MAX_N + 1],
                          int degrees[MAX_N + 1], int n) {
    polynomials[1][0] = -1;
    polynomials[1][1] = 1;
    degrees[1] = 1;
    for (int k = 2; k <= n; ++k) {
        int64_t divisor[MAX_N + 1] = {1};
        int divisor_degree = 0;
        for (int d = 1; d < k; ++d) {
            if (k % d != 0) continue;
            int64_t product[MAX_N + 1] = {0};
            for (int i = 0; i <= divisor_degree; ++i)
                for (int j = 0; j <= degrees[d]; ++j)
                    product[i + j] += divisor[i] * polynomials[d][j];
            divisor_degree += degrees[d];
            for (int i = 0; i <= divisor_degree; ++i) divisor[i] = product[i];
        }

        int64_t remainder[MAX_N + 1] = {0};
        remainder[0] = -1;
        remainder[k] = 1;
        const int quotient_degree = k - divisor_degree;
        degrees[k] = quotient_degree;
        for (int q = quotient_degree; q >= 0; --q) {
            const int64_t leading = remainder[divisor_degree + q];
            polynomials[k][q] = leading;
            for (int j = 0; j <= divisor_degree; ++j)
                remainder[q + j] -= leading * divisor[j];
        }
    }
}

int64_t cyclotomic_polynomial_coefficients(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != 1) return -1;

    int64_t polynomials[MAX_N + 1][MAX_N + 1] = {{0}};
    int degrees[MAX_N + 1] = {0};
    build_through(polynomials, degrees, (int)n_value);
    const size_t coefficient_count = (size_t)degrees[n_value] + 1;
    const size_t required = coefficient_count * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < coefficient_count; ++index)
        store_i64_le(output, 8 * index, polynomials[n_value][index]);
    return (int64_t)required;
}
