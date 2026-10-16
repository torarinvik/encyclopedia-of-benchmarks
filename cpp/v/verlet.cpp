#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" int64_t verlet(const double *values, std::size_t length,
                           double *output, std::size_t capacity) {
    if (values == nullptr || length != 4) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (!std::isfinite(values[i])) return -1;

    if (values[0] < 2.0 || values[0] > 32.0 || std::floor(values[0]) != values[0] ||
        values[1] < -1.0 || values[1] > 1.0 ||
        values[2] < -1.0 || values[2] > 1.0 ||
        values[3] < 0.0 || values[3] > 4.0 || std::floor(values[3]) != values[3]) return -1;

    const std::size_t n = static_cast<std::size_t>(values[0]);
    const int code = static_cast<int>(values[3]);
    static constexpr double step_sizes[5] = {
        0.00390625, 0.0078125, 0.015625, 0.03125, 0.0625
    };
    const double dt = step_sizes[code];
    const double dt_squared = dt * dt;
    if (output == nullptr || capacity < 2 * n) return -2;

    output[0] = values[1];
    output[1] = values[1] + values[2] * dt + 0.5 * (-values[1]) * dt_squared;
    for (std::size_t i = 1; i < n - 1; ++i)
        output[i + 1] = 2.0 * output[i] - output[i - 1] + (-output[i]) * dt_squared;
    for (std::size_t i = 0; i < n; ++i) output[n + i] = static_cast<double>(i) * dt;
    return static_cast<int64_t>(2 * n);
}
