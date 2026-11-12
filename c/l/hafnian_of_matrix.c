#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MOD INT64_C(998244353)
#define MAX_INPUT_VALUES (1 + MAX_N * MAX_N)
#define STATES (1u << MAX_N)

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t hafnian_of_matrix(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 2 || n_value > MAX_N || n_value % 2 != 0) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + n * n) return -1;

    int64_t matrix[MAX_N * MAX_N];
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const int64_t value = input[1 + row * n + column];
            if (value < 0 || value >= MOD || (row == column && value != 0))
                return -1;
            matrix[row * n + column] = value;
        }
    }
    for (size_t row = 0; row < n; ++row)
        for (size_t column = 0; column < row; ++column)
            if (matrix[row * n + column] != matrix[column * n + row]) return -1;

    int64_t dp[STATES] = {0};
    dp[0] = 1;
    const unsigned full = (1u << n) - 1u;
    for (unsigned mask = 1; mask <= full; ++mask) {
        unsigned bits = mask;
        unsigned parity = 0;
        while (bits != 0) {
            parity ^= 1u;
            bits &= bits - 1u;
        }
        if (parity != 0) continue;

        size_t first = 0;
        while ((mask & (1u << first)) == 0) ++first;
        const unsigned without_first = mask ^ (1u << first);
        for (size_t second = first + 1; second < n; ++second) {
            const unsigned second_bit = 1u << second;
            if ((without_first & second_bit) == 0) continue;
            const unsigned rest = without_first ^ second_bit;
            dp[mask] = (dp[mask] + matrix[first * n + second] * dp[rest]) % MOD;
        }
    }

    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, dp[full]);
    return 8;
}
