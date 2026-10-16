#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t verlet(const double *values, size_t length,
               double *output, size_t capacity) {
    if (values == NULL || length != 4) return -1;
    for (size_t i = 0; i < length; ++i)
        if (!isfinite(values[i])) return -1;

    if (values[0] < 2.0 || values[0] > 32.0 || floor(values[0]) != values[0] ||
        values[1] < -1.0 || values[1] > 1.0 ||
        values[2] < -1.0 || values[2] > 1.0 ||
        values[3] < 0.0 || values[3] > 4.0 || floor(values[3]) != values[3]) return -1;

    const size_t n = (size_t)values[0];
    const int dt_code = (int)values[3];
    static const double step_sizes[5] = {
        0.00390625, 0.0078125, 0.015625, 0.03125, 0.0625
    };
    const double dt = step_sizes[dt_code];
    const double dt_squared = dt * dt;
    if (output == NULL || capacity < 2 * n) return -2;

    output[0] = values[1];
    output[1] = values[1] + values[2] * dt + 0.5 * (-values[1]) * dt_squared;
    for (size_t i = 1; i < n - 1; ++i)
        output[i + 1] = 2.0 * output[i] - output[i - 1] + (-output[i]) * dt_squared;
    for (size_t i = 0; i < n; ++i) output[n + i] = (double)i * dt;
    return (int64_t)(2 * n);
}
