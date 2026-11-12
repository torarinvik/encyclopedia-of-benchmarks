#include <stddef.h>
#include <stdint.h>

#define MAX_N 6
#define MODULUS INT64_C(998244353)

static int64_t minor_determinant(const int64_t matrix[MAX_N * MAX_N],
                                 size_t n, size_t skip_row, size_t skip_column) {
    const size_t dimension = n - 1;
    if (dimension == 0) return 1;

    int64_t minor[MAX_N * MAX_N] = {0};
    size_t target_row = 0;
    for (size_t row = 0; row < n; ++row) {
        if (row == skip_row) continue;
        size_t target_column = 0;
        for (size_t column = 0; column < n; ++column) {
            if (column == skip_column) continue;
            minor[target_row * dimension + target_column] = matrix[row * n + column];
            ++target_column;
        }
        ++target_row;
    }

    int64_t dp[1U << (MAX_N - 1)] = {0};
    dp[0] = 1;
    const size_t limit = (size_t)1 << dimension;
    for (size_t mask = 0; mask < limit; ++mask) {
        size_t row = 0;
        for (size_t bits = mask; bits != 0; bits >>= 1) row += bits & 1U;
        if (row == dimension) continue;
        for (size_t column = 0; column < dimension; ++column) {
            if ((mask & ((size_t)1 << column)) != 0) continue;
            size_t inversions = 0;
            for (size_t prior = column + 1; prior < dimension; ++prior)
                inversions += (mask >> prior) & 1U;
            const size_t next = mask | ((size_t)1 << column);
            const int64_t term = dp[mask] * minor[row * dimension + column] % MODULUS;
            if ((inversions & 1U) == 0)
                dp[next] = (dp[next] + term) % MODULUS;
            else
                dp[next] = (dp[next] - term + MODULUS) % MODULUS;
        }
    }
    return dp[limit - 1];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t adjugate_matrix(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 1 + MAX_N * MAX_N) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + n * n) return -1;

    int64_t matrix[MAX_N * MAX_N] = {0};
    for (size_t index = 0; index < n * n; ++index) {
        const int64_t value = input[1 + index];
        if (value < 0 || value >= MODULUS) return -1;
        matrix[index] = value;
    }

    const size_t output_bytes = 8 * n * n;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            int64_t value = minor_determinant(matrix, n, column, row);
            if ((row + column) & 1U) value = value == 0 ? 0 : MODULUS - value;
            store_i64_le(output, 8 * (row * n + column), value);
        }
    }
    return (int64_t)output_bytes;
}
