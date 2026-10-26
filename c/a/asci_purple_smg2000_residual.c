/* Clean-room bounded residual profile; see package README and RIGHTS.md. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_SIDE = 5, MAX_CELLS = 125, MAX_INPUT = 253 };

int64_t asci_purple_smg2000_residual(const double *input, size_t length,
                                     double *output, size_t capacity) {
    if (input == NULL || length < 19 || length > MAX_INPUT) return -1;
    for (size_t q = 0; q < 3; ++q)
        if (!isfinite(input[q]) || trunc(input[q]) != input[q] ||
            input[q] < 2.0 || input[q] > MAX_SIDE) return -1;
    const size_t nx = (size_t)input[0], ny = (size_t)input[1], nz = (size_t)input[2];
    const size_t cells = nx * ny * nz;
    if (length != 3 + 2 * cells) return -1;
    for (size_t q = 3; q < length; ++q)
        if (!isfinite(input[q]) || trunc(input[q]) != input[q] ||
            input[q] < -1000.0 || input[q] > 1000.0) return -1;
    if (output == NULL || capacity < cells) return -2;

    const size_t stride_i = ny * nz, stride_j = nz;
    for (size_t i = 0; i < nx; ++i)
        for (size_t j = 0; j < ny; ++j)
            for (size_t k = 0; k < nz; ++k) {
                const size_t q = i * stride_i + j * stride_j + k;
                const int64_t x = (int64_t)input[3 + q];
                int64_t ax_tenths = 222 * x;
                if (i > 0) ax_tenths -= (int64_t)input[3 + q - stride_i];
                if (i + 1 < nx) ax_tenths -= (int64_t)input[3 + q + stride_i];
                if (j > 0) ax_tenths -= 10 * (int64_t)input[3 + q - stride_j];
                if (j + 1 < ny) ax_tenths -= 10 * (int64_t)input[3 + q + stride_j];
                if (k > 0) ax_tenths -= 100 * (int64_t)input[3 + q - 1];
                if (k + 1 < nz) ax_tenths -= 100 * (int64_t)input[3 + q + 1];
                const int64_t b = (int64_t)input[3 + cells + q];
                output[q] = (double)(10 * b - ax_tenths) / 10.0;
            }
    return (int64_t)cells;
}
