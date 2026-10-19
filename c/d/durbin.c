#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 40

int64_t durbin(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 1 || !isfinite(input[0]) ||
        trunc(input[0]) != input[0] || input[0] < 1.0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (output == NULL || capacity < n) return -2;

    double r[MAX_N], y[MAX_N], z[MAX_N];
    for (size_t i = 0; i < n; ++i) r[i] = (double)(n + 1 - i);
    y[0] = -r[0];
    double beta = 1.0;
    double alpha = -r[0];
    for (size_t k = 1; k < n; ++k) {
        beta = (1.0 - alpha * alpha) * beta;
        double sum = 0.0;
        for (size_t i = 0; i < k; ++i) sum += r[k - i - 1] * y[i];
        alpha = -(r[k] + sum) / beta;
        for (size_t i = 0; i < k; ++i) z[i] = y[i] + alpha * y[k - i - 1];
        for (size_t i = 0; i < k; ++i) y[i] = z[i];
        y[k] = alpha;
    }
    for (size_t i = 0; i < n; ++i) output[i] = y[i];
    return (int64_t)n;
}
