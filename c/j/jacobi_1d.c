#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 30
#define MAX_TSTEPS 20

int64_t jacobi_1d(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 2 || !isfinite(input[0]) || !isfinite(input[1]) ||
        trunc(input[0]) != input[0] || trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > MAX_N || input[1] < 0.0 || input[1] > MAX_TSTEPS) return -1;
    const size_t n = (size_t)input[0];
    const size_t tsteps = (size_t)input[1];
    if (output == NULL || capacity < n) return -2;

    double a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = ((double)i + 2.0) / (double)n;
        b[i] = ((double)i + 3.0) / (double)n;
    }
    for (size_t t = 0; t < tsteps; ++t) {
        for (size_t i = 1; i + 1 < n; ++i) b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1]);
        for (size_t i = 1; i + 1 < n; ++i) a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1]);
    }
    for (size_t i = 0; i < n; ++i) output[i] = a[i];
    return (int64_t)n;
}
