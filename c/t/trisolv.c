#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 40

int64_t trisolv(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 1 || !isfinite(input[0]) ||
        trunc(input[0]) != input[0] || input[0] < 1.0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (output == NULL || capacity < n) return -2;

    double lower[MAX_N][MAX_N] = {{0.0}};
    double b[MAX_N] = {0.0};
    double x[MAX_N] = {0.0};
    for (size_t i = 0; i < n; ++i) {
        b[i] = (double)i;
        for (size_t j = 0; j <= i; ++j)
            lower[i][j] = (double)(i + n - j + 1) * 2.0 / (double)n;
    }
    for (size_t i = 0; i < n; ++i) {
        x[i] = b[i];
        for (size_t j = 0; j < i; ++j) x[i] -= lower[i][j] * x[j];
        x[i] /= lower[i][i];
    }
    for (size_t i = 0; i < n; ++i) output[i] = x[i];
    return (int64_t)n;
}
