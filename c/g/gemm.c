#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double gemm(const int64_t *values, size_t length) {
    if (values == NULL || length != 3 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION || values[2] < 1 || values[2] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t ni = (size_t)values[0], nj = (size_t)values[1], nk = (size_t)values[2];
    const double alpha = 1.5, beta = 1.2;
    double c[MAX_CELLS], a[MAX_CELLS], b[MAX_CELLS];
    for (size_t i = 0; i < ni; ++i)
        for (size_t j = 0; j < nj; ++j)
            c[i * nj + j] = (double)((i * j + 1) % ni) / (double)ni;
    for (size_t i = 0; i < ni; ++i)
        for (size_t k = 0; k < nk; ++k)
            a[i * nk + k] = (double)(i * (k + 1) % nk) / (double)nk;
    for (size_t k = 0; k < nk; ++k)
        for (size_t j = 0; j < nj; ++j)
            b[k * nj + j] = (double)(k * (j + 2) % nj) / (double)nj;
    for (size_t i = 0; i < ni; ++i) {
        for (size_t j = 0; j < nj; ++j) c[i * nj + j] *= beta;
        for (size_t k = 0; k < nk; ++k)
            for (size_t j = 0; j < nj; ++j)
                c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
    }
    double checksum = 0.0;
    for (size_t i = 0; i < ni; ++i)
        for (size_t j = 0; j < nj; ++j) checksum += c[i * nj + j];
    return checksum;
}
