#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double mvt(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t n = (size_t)values[0];
    double x1[MAX_DIMENSION], x2[MAX_DIMENSION], y1[MAX_DIMENSION], y2[MAX_DIMENSION];
    double matrix[MAX_CELLS];
    for (size_t i = 0; i < n; ++i) {
        x1[i] = (double)(i % n) / (double)n;
        x2[i] = (double)((i + 1) % n) / (double)n;
        y1[i] = (double)((i + 3) % n) / (double)n;
        y2[i] = (double)((i + 4) % n) / (double)n;
        for (size_t j = 0; j < n; ++j)
            matrix[i * n + j] = (double)((i * j) % n) / (double)n;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            x1[i] = x1[i] + matrix[i * n + j] * y1[j];
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            x2[i] = x2[i] + matrix[j * n + i] * y2[j];
    double checksum = 0.0;
    for (size_t i = 0; i < n; ++i) checksum += x1[i];
    for (size_t i = 0; i < n; ++i) checksum += x2[i];
    return checksum;
}
