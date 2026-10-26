/* Clean-room bounded Parboil seven-point Laplacian profile. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 125
#define MAX_INPUT_LENGTH 129

int64_t parboil_stencil_laplacian(const double *input, size_t length,
                                  double *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < 4; ++i) {
        if (!isfinite(input[i]) || trunc(input[i]) != input[i]) return -1;
    }
    if (input[0] < 3 || input[0] > 5 || input[1] < 3 || input[1] > 5 ||
        input[2] < 3 || input[2] > 5 || input[3] < 1 || input[3] > 4) return -1;
    size_t nx = (size_t)input[0], ny = (size_t)input[1];
    size_t nz = (size_t)input[2], steps = (size_t)input[3];
    size_t cells = nx * ny * nz;
    if (length != 4 + cells) return -1;
    for (size_t q = 0; q < cells; ++q) {
        double value = input[4 + q];
        if (!isfinite(value) || value < -8.0 || value > 8.0) return -1;
    }
    if (output == NULL || capacity < cells) return -2;

    float a[MAX_CELLS], b[MAX_CELLS];
    double staged[MAX_CELLS];
    for (size_t q = 0; q < cells; ++q) a[q] = b[q] = (float)input[4 + q];
    const float c0 = 1.0f / 6.0f;
    const float c1 = (1.0f / 6.0f) / 6.0f;
    for (size_t step = 0; step < steps; ++step) {
        for (size_t i = 1; i + 1 < nx; ++i) {
            for (size_t j = 1; j + 1 < ny; ++j) {
                for (size_t k = 1; k + 1 < nz; ++k) {
                    size_t q = i + nx * (j + ny * k);
                    float sum = a[q + nx * ny] + a[q - nx * ny];
                    sum = sum + a[q + nx];
                    sum = sum + a[q - nx];
                    sum = sum + a[q + 1];
                    sum = sum + a[q - 1];
                    float neighbor_term = sum * c1;
                    float center_term = a[q] * c0;
                    b[q] = neighbor_term - center_term;
                }
            }
        }
        for (size_t q = 0; q < cells; ++q) {
            float temp = a[q];
            a[q] = b[q];
            b[q] = temp;
        }
    }
    for (size_t q = 0; q < cells; ++q) staged[q] = (double)a[q];
    for (size_t q = 0; q < cells; ++q) output[q] = staged[q];
    return (int64_t)cells;
}
