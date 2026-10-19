#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double polybench_symm(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION) return INVALID_RESULT;
    const size_t m = (size_t)values[0], n = (size_t)values[1];
    double a[MAX_CELLS], b[MAX_CELLS], c[MAX_CELLS];
    const double alpha = 1.5, beta = 1.2;
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < n; ++j) {
            c[i * n + j] = (double)((i + j) % 100) / (double)m;
            b[i * n + j] = (double)((n + i - j) % 100) / (double)m;
        }
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < m; ++j)
            a[i * m + j] = j <= i ? (double)((i + j) % 100) / (double)m : -999.0;
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < n; ++j) {
            double temp2 = 0.0;
            for (size_t k = 0; k < i; ++k) {
                c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k];
                temp2 = temp2 + b[k * n + j] * a[i * m + k];
            }
            c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2;
        }
    double result = 0.0;
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < n; ++j) result += c[i * n + j];
    return result;
}
