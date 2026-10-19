#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 30
#define MAX_TSTEPS 20

int64_t jacobi_2d(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 2 || !isfinite(input[0]) || !isfinite(input[1]) ||
        trunc(input[0]) != input[0] || trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > MAX_N || input[1] < 0.0 || input[1] > MAX_TSTEPS) return -1;
    const size_t n = (size_t)input[0];
    const size_t tsteps = (size_t)input[1];
    const size_t count = n * n;
    if (output == NULL || capacity < count) return -2;

    double a[MAX_N][MAX_N], b[MAX_N][MAX_N];
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            a[i][j] = ((double)i * (double)(j + 2) + 2.0) / (double)n;
            b[i][j] = ((double)i * (double)(j + 3) + 3.0) / (double)n;
        }
    }
    for (size_t t = 0; t < tsteps; ++t) {
        for (size_t i = 1; i + 1 < n; ++i) {
            for (size_t j = 1; j + 1 < n; ++j)
                b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j]);
        }
        for (size_t i = 1; i + 1 < n; ++i) {
            for (size_t j = 1; j + 1 < n; ++j)
                a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j]);
        }
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j) output[i * n + j] = a[i][j];
    return (int64_t)count;
}
