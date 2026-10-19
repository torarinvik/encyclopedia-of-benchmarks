#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double polybench_cholesky(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t n = (size_t)values[0];
    double a[MAX_CELLS], product[MAX_CELLS];
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j <= i; ++j)
            a[i * n + j] = (double)(-((int64_t)j) % (int64_t)n) / (double)n + 1.0;
        for (size_t j = i + 1; j < n; ++j) a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (size_t r = 0; r < n; ++r)
        for (size_t s = 0; s < n; ++s) product[r * n + s] = 0.0;
    for (size_t t = 0; t < n; ++t)
        for (size_t r = 0; r < n; ++r)
            for (size_t s = 0; s < n; ++s)
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    for (size_t r = 0; r < n; ++r)
        for (size_t s = 0; s < n; ++s) a[r * n + s] = product[r * n + s];

    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < i; ++j) {
            for (size_t k = 0; k < j; ++k)
                a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k];
            a[i * n + j] = a[i * n + j] / a[j * n + j];
        }
        for (size_t k = 0; k < i; ++k)
            a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k];
        a[i * n + i] = sqrt(a[i * n + i]);
    }
    double result = 0.0;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j <= i; ++j) result += a[i * n + j];
    return result;
}
