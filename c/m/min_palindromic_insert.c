#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MPI_MAX_N 256
#define MPI_MAX_INPUT 257
#define MPI_MAX_OUTPUT 527

static size_t mpi_write_i64(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[position++] = (uint8_t)(bits >> (8 * i));
    return position;
}

int64_t min_palindromic_insert(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MPI_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MPI_MAX_N || length != (size_t)(n_value + 1)) return -1;
    const size_t n = (size_t)n_value;
    uint8_t chars[MPI_MAX_N];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
        chars[i] = (uint8_t)input[i + 1];
    }

    uint16_t dp[MPI_MAX_N][MPI_MAX_N] = {{0}};
    for (size_t span = 2; span <= n; ++span) {
        for (size_t left = 0; left + span <= n; ++left) {
            const size_t right = left + span - 1;
            if (chars[left] == chars[right]) dp[left][right] = span > 2 ? dp[left + 1][right - 1] : 0;
            else {
                const uint16_t a = dp[left + 1][right];
                const uint16_t b = dp[left][right - 1];
                dp[left][right] = (a < b ? a : b) + 1;
            }
        }
    }

    const size_t insertions = dp[0][n - 1];
    const size_t palindrome_length = n + insertions;
    uint8_t palindrome[MPI_MAX_N * 2 - 1];
    size_t left = 0, right = n - 1;
    size_t out_left = 0, out_right = palindrome_length - 1;
    while (left <= right) {
        if (chars[left] == chars[right]) {
            palindrome[out_left] = chars[left];
            palindrome[out_right] = chars[right];
            ++left;
            if (right == 0) break;
            --right;
        } else if (dp[left + 1][right] < dp[left][right - 1]) {
            palindrome[out_left] = chars[left];
            palindrome[out_right] = chars[left];
            ++left;
        } else {
            palindrome[out_left] = chars[right];
            palindrome[out_right] = chars[right];
            if (right == 0) break;
            --right;
        }
        ++out_left;
        if (out_right == 0) break;
        --out_right;
    }

    uint8_t payload[MPI_MAX_OUTPUT];
    size_t written = 0;
    written = mpi_write_i64(payload, written, (int64_t)insertions);
    written = mpi_write_i64(payload, written, (int64_t)palindrome_length);
    memcpy(payload + written, palindrome, palindrome_length);
    written += palindrome_length;
    if (output == NULL || output_capacity < written) return -2;
    memcpy(output, payload, written);
    return (int64_t)written;
}
