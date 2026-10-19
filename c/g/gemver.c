#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double gemver(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t n = (size_t)values[0];
    const double alpha = 1.5, beta = 1.2, fn = (double)n;
    double a[MAX_CELLS] = {0.0};
    double u1[MAX_DIMENSION], v1[MAX_DIMENSION], u2[MAX_DIMENSION], v2[MAX_DIMENSION];
    double w[MAX_DIMENSION] = {0.0}, x[MAX_DIMENSION] = {0.0};
    double y[MAX_DIMENSION], z[MAX_DIMENSION];
    for (size_t i = 0; i < n; ++i) {
        u1[i] = (double)i;
        u2[i] = (((double)i + 1.0) / fn) / 2.0;
        v1[i] = (((double)i + 1.0) / fn) / 4.0;
        v2[i] = (((double)i + 1.0) / fn) / 6.0;
        y[i] = (((double)i + 1.0) / fn) / 8.0;
        z[i] = (((double)i + 1.0) / fn) / 9.0;
        for (size_t j = 0; j < n; ++j)
            a[i * n + j] = (double)((i * j) % n) / fn;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j];
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            x[i] = x[i] + beta * a[j * n + i] * y[j];
    for (size_t i = 0; i < n; ++i) x[i] = x[i] + z[i];
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            w[i] = w[i] + alpha * a[i * n + j] * x[j];
    double checksum = 0.0;
    for (size_t i = 0; i < n; ++i) checksum += w[i];
    return checksum;
}
