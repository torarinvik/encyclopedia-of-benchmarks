#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_SIDE = 6, MAX_CELLS = 216 };

int64_t himenobmtxpa(const double *input, size_t length,
                     double *output, size_t capacity)
{
    if (input == NULL || length != 4) return -1;
    for (size_t q = 0; q < 4; ++q)
        if (!isfinite(input[q]) || trunc(input[q]) != input[q]) return -1;
    if (input[0] < 2 || input[0] > MAX_SIDE || input[1] < 2 || input[1] > MAX_SIDE ||
        input[2] < 2 || input[2] > MAX_SIDE || input[3] < 1 || input[3] > 4) return -1;
    const size_t nx = (size_t)input[0], ny = (size_t)input[1];
    const size_t nz = (size_t)input[2], iterations = (size_t)input[3];
    if (output == NULL || capacity < 1) return -2;

    float p[MAX_CELLS] = {0.0f};
    float work[MAX_CELLS] = {0.0f};
    const float a3 = 1.0f / 6.0f;
    const float omega = 0.8f;
    const float denominator = (float)((nx - 1) * (nx - 1));
    for (size_t i = 0; i < nx; ++i)
        for (size_t j = 0; j < ny; ++j)
            for (size_t k = 0; k < nz; ++k) {
                const size_t q = i * ny * nz + j * nz + k;
                p[q] = (float)(i * i) / denominator;
            }

    float gosa = 0.0f;
    for (size_t iteration = 0; iteration < iterations; ++iteration) {
        gosa = 0.0f;
        for (size_t i = 1; i + 1 < nx; ++i)
            for (size_t j = 1; j + 1 < ny; ++j)
                for (size_t k = 1; k + 1 < nz; ++k) {
                    const size_t q = i * ny * nz + j * nz + k;
                    float s0 = p[q + ny * nz] + p[q + nz] + p[q + 1];
                    s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1];
                    const float ss = s0 * a3 - p[q];
                    gosa = gosa + ss * ss;
                    work[q] = p[q] + omega * ss;
                }
        for (size_t i = 1; i + 1 < nx; ++i)
            for (size_t j = 1; j + 1 < ny; ++j)
                for (size_t k = 1; k + 1 < nz; ++k) {
                    const size_t q = i * ny * nz + j * nz + k;
                    p[q] = work[q];
                }
    }
    output[0] = (double)gosa;
    return 1;
}
