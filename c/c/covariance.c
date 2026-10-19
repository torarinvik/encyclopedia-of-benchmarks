#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double covariance(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || values[0] < 2 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION) return INVALID_RESULT;
    const size_t n = (size_t)values[0], m = (size_t)values[1];
    const double float_n = (double)n;
    double data[MAX_CELLS], cov[MAX_CELLS], mean[MAX_DIMENSION];
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < m; ++j)
            data[i * m + j] = ((double)i * (double)j) / (double)m;
    for (size_t j = 0; j < m; ++j) {
        mean[j] = 0.0;
        for (size_t i = 0; i < n; ++i) mean[j] += data[i * m + j];
        mean[j] /= float_n;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < m; ++j) data[i * m + j] -= mean[j];
    for (size_t i = 0; i < m; ++i) {
        for (size_t j = i; j < m; ++j) {
            cov[i * m + j] = 0.0;
            for (size_t k = 0; k < n; ++k) cov[i * m + j] += data[k * m + i] * data[k * m + j];
            cov[i * m + j] /= float_n - 1.0;
            cov[j * m + i] = cov[i * m + j];
        }
    }
    double checksum = 0.0;
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < m; ++j) checksum += cov[i * m + j];
    return checksum;
}
