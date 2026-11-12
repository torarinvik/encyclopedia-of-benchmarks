#include <stddef.h>
#include <stdint.h>

#define MAX_N 32

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    union { double f; uint64_t u; } bits = { .f = value };
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits.u >> (8 * byte));
}

int64_t thomas_algorithm(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > 1 + 4 * MAX_N) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 4 * n) return -1;

    const int64_t *lower = input + 1;
    const int64_t *diagonal = lower + n;
    const int64_t *upper = diagonal + n;
    const int64_t *rhs = upper + n;
    if (lower[0] != 0 || upper[n - 1] != 0) return -1;
    for (size_t row = 0; row < n; ++row) {
        if (lower[row] < -16 || lower[row] > 16 ||
            upper[row] < -16 || upper[row] > 16 ||
            diagonal[row] < 17 || diagonal[row] > 64 ||
            rhs[row] < -1000 || rhs[row] > 1000) return -1;
        const int64_t lower_abs = lower[row] < 0 ? -lower[row] : lower[row];
        const int64_t upper_abs = upper[row] < 0 ? -upper[row] : upper[row];
        if (diagonal[row] <= lower_abs + upper_abs) return -1;
    }
    const size_t output_bytes = n * 8;
    if (output == NULL || capacity < output_bytes) return -2;

    double modified_upper[MAX_N] = {0.0};
    double modified_rhs[MAX_N] = {0.0};
    double solution[MAX_N] = {0.0};
    modified_upper[0] = (double)upper[0] / (double)diagonal[0];
    modified_rhs[0] = (double)rhs[0] / (double)diagonal[0];
    for (size_t row = 1; row < n; ++row) {
        const double pivot = (double)diagonal[row] -
            (double)lower[row] * modified_upper[row - 1];
        modified_upper[row] = row + 1 < n ? (double)upper[row] / pivot : 0.0;
        modified_rhs[row] = ((double)rhs[row] -
            (double)lower[row] * modified_rhs[row - 1]) / pivot;
    }
    solution[n - 1] = modified_rhs[n - 1];
    for (size_t row = n - 1; row-- > 0;)
        solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1];
    for (size_t row = 0; row < n; ++row)
        put_f64_le(output, row * 8, solution[row]);
    return (int64_t)output_bytes;
}
