#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_DIMENSION 32
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define MAX_TSTEPS 20

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t polybench_adi(const int64_t *values, size_t length,
                      uint8_t *output, size_t output_capacity) {
    if (values == NULL || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_TSTEPS) return -1;
    const size_t n = (size_t)values[0];
    const size_t tsteps = (size_t)values[1];
    const size_t cells = n * n;
    const size_t output_bytes = cells * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    double u[MAX_CELLS] = {0}, v[MAX_CELLS] = {0};
    double p[MAX_CELLS] = {0}, q[MAX_CELLS] = {0};
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            u[i * n + j] = (double)(i + n - j) / (double)n;

    const double dx = 1.0 / (double)n;
    const double dy = 1.0 / (double)n;
    const double dt = 1.0 / (double)tsteps;
    const double b1 = 2.0, b2 = 1.0;
    const double mul1 = b1 * dt / (dx * dx);
    const double mul2 = b2 * dt / (dy * dy);
    const double a = -mul1 / 2.0;
    const double b = 1.0 + mul1;
    const double c = a;
    const double d = -mul2 / 2.0;
    const double e = 1.0 + mul2;
    const double f = d;

    for (size_t t = 1; t <= tsteps; ++t) {
        for (size_t i = 1; i < n - 1; ++i) {
            v[i] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = v[i];
            for (size_t j = 1; j < n - 1; ++j) {
                p[i * n + j] = -c / (a * p[i * n + j - 1] + b);
                q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
                                - f * u[j * n + i + 1] - a * q[i * n + j - 1])
                               / (a * p[i * n + j - 1] + b);
            }
            v[(n - 1) * n + i] = 1.0;
            for (size_t j = n - 1; j > 1;) {
                --j;
                v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j];
            }
        }

        for (size_t i = 1; i < n - 1; ++i) {
            u[i * n] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = u[i * n];
            for (size_t j = 1; j < n - 1; ++j) {
                p[i * n + j] = -f / (d * p[i * n + j - 1] + e);
                q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
                                - c * v[(i + 1) * n + j] - d * q[i * n + j - 1])
                               / (d * p[i * n + j - 1] + e);
            }
            u[i * n + n - 1] = 1.0;
            for (size_t j = n - 1; j > 1;) {
                --j;
                u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j];
            }
        }
    }

    for (size_t index = 0; index < cells; ++index)
        write_f64_le(output, index * 8, u[index]);
    return (int64_t)output_bytes;
}
