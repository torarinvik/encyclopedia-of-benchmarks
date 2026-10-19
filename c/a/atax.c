#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double atax(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION) return INVALID_RESULT;
    const size_t m = (size_t)values[0], n = (size_t)values[1];
    double matrix[MAX_CELLS], x[MAX_DIMENSION], y[MAX_DIMENSION], temporary[MAX_DIMENSION];
    const double fn = (double)n;
    for (size_t i = 0; i < n; ++i) x[i] = 1.0 + (double)i / fn;
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < n; ++j)
            matrix[i * n + j] = (double)((i + j) % n) / (double)(5 * m);
    for (size_t i = 0; i < n; ++i) y[i] = 0.0;
    for (size_t i = 0; i < m; ++i) {
        temporary[i] = 0.0;
        for (size_t j = 0; j < n; ++j)
            temporary[i] = temporary[i] + matrix[i * n + j] * x[j];
        for (size_t j = 0; j < n; ++j)
            y[j] = y[j] + matrix[i * n + j] * temporary[i];
    }
    double checksum = 0.0;
    for (size_t j = 0; j < n; ++j) checksum += y[j];
    return checksum;
}
