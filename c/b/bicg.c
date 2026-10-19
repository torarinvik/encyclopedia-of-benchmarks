#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double bicg(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION) return INVALID_RESULT;
    const size_t m = (size_t)values[0], n = (size_t)values[1];
    double matrix[MAX_CELLS], p[MAX_DIMENSION], r[MAX_DIMENSION];
    double s[MAX_DIMENSION], q[MAX_DIMENSION];
    for (size_t i = 0; i < m; ++i) p[i] = (double)(i % m) / (double)m;
    for (size_t i = 0; i < n; ++i) {
        r[i] = (double)(i % n) / (double)n;
        for (size_t j = 0; j < m; ++j)
            matrix[i * m + j] = (double)((i * (j + 1)) % n) / (double)n;
    }
    for (size_t i = 0; i < m; ++i) s[i] = 0.0;
    for (size_t i = 0; i < n; ++i) {
        q[i] = 0.0;
        for (size_t j = 0; j < m; ++j) {
            s[j] = s[j] + r[i] * matrix[i * m + j];
            q[i] = q[i] + matrix[i * m + j] * p[j];
        }
    }
    double checksum = 0.0;
    for (size_t j = 0; j < m; ++j) checksum += s[j];
    for (size_t i = 0; i < n; ++i) checksum += q[i];
    return checksum;
}
