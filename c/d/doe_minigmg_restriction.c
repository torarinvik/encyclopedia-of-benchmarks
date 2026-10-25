/* Bounded cell-centered restriction from the miniGMG multigrid operator. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double doe_minigmg_restriction(const int64_t *values, size_t length) {
    if (values == NULL || length < 11 || length > 515) return INVALID_RESULT;

    const int64_t nx_raw = values[0];
    const int64_t ny_raw = values[1];
    const int64_t nz_raw = values[2];
    if (nx_raw < 2 || nx_raw > 8 || (nx_raw & 1) != 0 ||
        ny_raw < 2 || ny_raw > 8 || (ny_raw & 1) != 0 ||
        nz_raw < 2 || nz_raw > 8 || (nz_raw & 1) != 0) return INVALID_RESULT;

    const size_t nx = (size_t)nx_raw;
    const size_t ny = (size_t)ny_raw;
    const size_t nz = (size_t)nz_raw;
    const size_t cells = nx * ny * nz;
    if (length != 3 + cells) return INVALID_RESULT;
    for (size_t i = 0; i < cells; ++i)
        if (values[3 + i] < -32768 || values[3 + i] > 32767) return INVALID_RESULT;

    const size_t coarse_nx = nx / 2;
    const size_t coarse_ny = ny / 2;
    const size_t coarse_nz = nz / 2;
    const size_t plane = nx * ny;
    double checksum = 0.0;
    size_t coarse_index = 0;

    for (size_t k = 0; k < coarse_nz; ++k) {
        for (size_t j = 0; j < coarse_ny; ++j) {
            for (size_t i = 0; i < coarse_nx; ++i) {
                const size_t base = 3 + 2 * i + 2 * j * nx + 2 * k * plane;
                const double sum = (double)values[base] + (double)values[base + 1] +
                    (double)values[base + nx] + (double)values[base + nx + 1] +
                    (double)values[base + plane] + (double)values[base + plane + 1] +
                    (double)values[base + plane + nx] + (double)values[base + plane + nx + 1];
                const double restricted = sum * 0.125;
                const double weight = (double)(coarse_index + 1);
                checksum += weight * restricted * restricted;
                ++coarse_index;
            }
        }
    }
    return checksum;
}
