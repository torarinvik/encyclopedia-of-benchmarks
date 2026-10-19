#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 16
#define MAX_A_CELLS (MAX_DIMENSION * MAX_DIMENSION * MAX_DIMENSION)
#define MAX_C4_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double doitgen(const int64_t *values, size_t length) {
    if (values == NULL || length != 3 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION || values[2] < 1 || values[2] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t nr = (size_t)values[0], nq = (size_t)values[1], np = (size_t)values[2];
    double a[MAX_A_CELLS], c4[MAX_C4_CELLS], sum[MAX_DIMENSION];
    for (size_t r = 0; r < nr; ++r)
        for (size_t q = 0; q < nq; ++q)
            for (size_t p = 0; p < np; ++p)
                a[(r * nq + q) * np + p] = (double)((r * q + p) % np) / (double)np;
    for (size_t i = 0; i < np; ++i)
        for (size_t j = 0; j < np; ++j)
            c4[i * np + j] = (double)(i * j % np) / (double)np;
    for (size_t r = 0; r < nr; ++r)
        for (size_t q = 0; q < nq; ++q) {
            for (size_t p = 0; p < np; ++p) {
                sum[p] = 0.0;
                for (size_t s = 0; s < np; ++s)
                    sum[p] += a[(r * nq + q) * np + s] * c4[s * np + p];
            }
            for (size_t p = 0; p < np; ++p) a[(r * nq + q) * np + p] = sum[p];
        }
    double checksum = 0.0;
    for (size_t r = 0; r < nr; ++r)
        for (size_t q = 0; q < nq; ++q)
            for (size_t p = 0; p < np; ++p) checksum += a[(r * nq + q) * np + p];
    return checksum;
}
