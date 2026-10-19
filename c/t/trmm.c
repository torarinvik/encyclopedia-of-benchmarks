/* PolyBench/C trmm kernel, bounded cross-language port. See benchmarks/t/trmm/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_M 8
#define MAX_N 8

int64_t trmm(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 2 || !isfinite(input[0]) || !isfinite(input[1]) ||
        trunc(input[0]) != input[0] || trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > MAX_M || input[1] < 1.0 || input[1] > MAX_N) return -1;
    const size_t m = (size_t)input[0], n = (size_t)input[1];
    const size_t required = m * n;
    if (output == NULL || capacity < required) return -2;

    double a[MAX_M][MAX_M] = {{0.0}}, b[MAX_M][MAX_N] = {{0.0}};
    const double alpha = 1.5;
    for (size_t i = 0; i < m; ++i) {
        for (size_t j = 0; j < i; ++j) a[i][j] = (double)((i + j) % m) / (double)m;
        a[i][i] = 1.0;
        for (size_t j = 0; j < n; ++j) b[i][j] = (double)((n + i - j) % n) / (double)n;
    }
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < n; ++j) {
            for (size_t k = i + 1; k < m; ++k) b[i][j] += a[k][i] * b[k][j];
            b[i][j] = alpha * b[i][j];
        }
    double staged[MAX_M * MAX_N];
    for (size_t i = 0; i < m; ++i) for (size_t j = 0; j < n; ++j) staged[i*n+j] = b[i][j];
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
