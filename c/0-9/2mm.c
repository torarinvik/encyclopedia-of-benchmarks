#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 16
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double two_mm(const int64_t *values, size_t length) {
    if (values == NULL || length != 4) return INVALID_RESULT;
    for (size_t i = 0; i < 4; ++i)
        if (values[i] < 1 || values[i] > MAX_DIMENSION) return INVALID_RESULT;
    const size_t ni = (size_t)values[0], nj = (size_t)values[1];
    const size_t nk = (size_t)values[2], nl = (size_t)values[3];
    const double alpha = 1.5, beta = 1.2;
    double a[MAX_CELLS], b[MAX_CELLS], c[MAX_CELLS], d[MAX_CELLS], tmp[MAX_CELLS];
    for (size_t i = 0; i < ni; ++i)
        for (size_t k = 0; k < nk; ++k) a[i * nk + k] = (double)((i * k + 1) % ni) / (double)ni;
    for (size_t k = 0; k < nk; ++k)
        for (size_t j = 0; j < nj; ++j) b[k * nj + j] = (double)(k * (j + 1) % nj) / (double)nj;
    for (size_t j = 0; j < nj; ++j)
        for (size_t l = 0; l < nl; ++l) c[j * nl + l] = (double)((j * (l + 3) + 1) % nl) / (double)nl;
    for (size_t i = 0; i < ni; ++i)
        for (size_t l = 0; l < nl; ++l) d[i * nl + l] = (double)(i * (l + 2) % nk) / (double)nk;
    for (size_t i = 0; i < ni; ++i)
        for (size_t j = 0; j < nj; ++j) {
            tmp[i * nj + j] = 0.0;
            for (size_t k = 0; k < nk; ++k) tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
        }
    for (size_t i = 0; i < ni; ++i)
        for (size_t l = 0; l < nl; ++l) {
            d[i * nl + l] *= beta;
            for (size_t j = 0; j < nj; ++j) d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l];
        }
    double checksum = 0.0;
    for (size_t i = 0; i < ni; ++i)
        for (size_t l = 0; l < nl; ++l) checksum += d[i * nl + l];
    return checksum;
}
