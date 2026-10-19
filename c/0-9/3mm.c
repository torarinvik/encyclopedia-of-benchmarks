#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 16
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double three_mm(const int64_t *values, size_t length) {
    if (values == NULL || length != 5) return INVALID_RESULT;
    for (size_t i = 0; i < 5; ++i)
        if (values[i] < 1 || values[i] > MAX_DIMENSION) return INVALID_RESULT;
    const size_t ni = (size_t)values[0], nj = (size_t)values[1];
    const size_t nk = (size_t)values[2], nl = (size_t)values[3], nm = (size_t)values[4];
    double a[MAX_CELLS], b[MAX_CELLS], c[MAX_CELLS], d[MAX_CELLS];
    double e[MAX_CELLS], f[MAX_CELLS], g[MAX_CELLS];
    for (size_t i = 0; i < ni; ++i)
        for (size_t k = 0; k < nk; ++k) a[i * nk + k] = (double)((i * k + 1) % ni) / (double)(5 * ni);
    for (size_t k = 0; k < nk; ++k)
        for (size_t j = 0; j < nj; ++j) b[k * nj + j] = (double)((k * (j + 1) + 2) % nj) / (double)(5 * nj);
    for (size_t i = 0; i < nj; ++i)
        for (size_t j = 0; j < nm; ++j) c[i * nm + j] = (double)(i * (j + 3) % nl) / (double)(5 * nl);
    for (size_t i = 0; i < nm; ++i)
        for (size_t j = 0; j < nl; ++j) d[i * nl + j] = (double)((i * (j + 2) + 2) % nk) / (double)(5 * nk);
    for (size_t i = 0; i < ni; ++i)
        for (size_t j = 0; j < nj; ++j) {
            e[i * nj + j] = 0.0;
            for (size_t k = 0; k < nk; ++k) e[i * nj + j] += a[i * nk + k] * b[k * nj + j];
        }
    for (size_t i = 0; i < nj; ++i)
        for (size_t j = 0; j < nl; ++j) {
            f[i * nl + j] = 0.0;
            for (size_t k = 0; k < nm; ++k) f[i * nl + j] += c[i * nm + k] * d[k * nl + j];
        }
    for (size_t i = 0; i < ni; ++i)
        for (size_t j = 0; j < nl; ++j) {
            g[i * nl + j] = 0.0;
            for (size_t k = 0; k < nj; ++k) g[i * nl + j] += e[i * nj + k] * f[k * nl + j];
        }
    double checksum = 0.0;
    for (size_t i = 0; i < ni; ++i)
        for (size_t j = 0; j < nl; ++j) checksum += g[i * nl + j];
    return checksum;
}
