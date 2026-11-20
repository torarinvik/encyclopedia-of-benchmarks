#include <math.h>
#include <stddef.h>
#include <stdint.h>

static int exact_integer(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

int64_t lanczos_symmetric_tridiagonalization(const double *input, size_t input_length,
                                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > 19) return -1;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return -1;
    int n, k;
    if (!exact_integer(input[0], 1, 4, &n) || !exact_integer(input[1], 1, 4, &k) ||
        k > n || input_length != (size_t)(2 + n * n)) return -1;
    for (int row = 0; row < n; ++row) {
        for (int col = 0; col < n; ++col) {
            int entry;
            if (!exact_integer(input[2 + row * n + col], -4, 4, &entry)) return -1;
            if (input[2 + row * n + col] != input[2 + col * n + row]) return -1;
        }
    }
    const size_t required = (size_t)(2 * k);
    if (output == NULL || output_capacity < required) return -2;

    double previous[4] = {0.0}, current[4] = {0.0}, product[4] = {0.0};
    double residual[4] = {0.0}, next[4] = {0.0};
    double diagonal[4] = {0.0}, off_diagonal[3] = {0.0};
    current[0] = 1.0;
    double previous_beta = 0.0;
    for (int step = 0; step < k; ++step) {
        for (int row = 0; row < n; ++row) {
            product[row] = 0.0;
            for (int col = 0; col < n; ++col)
                product[row] += input[2 + row * n + col] * current[col];
        }
        double alpha = 0.0;
        for (int index = 0; index < n; ++index) alpha += current[index] * product[index];
        if (!isfinite(alpha)) return -3;
        diagonal[step] = alpha;
        if (step + 1 == k) break;
        double norm_squared = 0.0;
        for (int index = 0; index < n; ++index) {
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index];
            norm_squared += residual[index] * residual[index];
        }
        if (!isfinite(norm_squared) || norm_squared < 0.0) return -3;
        const double beta = sqrt(norm_squared);
        if (!isfinite(beta) || beta <= 9.094947017729282e-13) return -3;
        off_diagonal[step] = beta;
        for (int index = 0; index < n; ++index) next[index] = residual[index] / beta;
        for (int index = 0; index < n; ++index) previous[index] = current[index];
        for (int index = 0; index < n; ++index) current[index] = next[index];
        previous_beta = beta;
    }
    output[0] = (double)k;
    for (int index = 0; index < k; ++index) output[1 + index] = diagonal[index];
    for (int index = 0; index < k - 1; ++index) output[1 + k + index] = off_diagonal[index];
    return (int64_t)required;
}
