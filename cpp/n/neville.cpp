#include <cstddef>
#include <cstdint>

extern "C" double neville(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 4 || length > 34) return -1.0e300;
    const auto count = values[0], target_i = values[1];
    if (count < 1 || count > 16 || length != static_cast<std::size_t>(2 * count + 2) || target_i < -1000000 || target_i > 1000000) return -1.0e300;
    double x[16], p[16];
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const auto xi = values[2 + 2 * i], yi = values[3 + 2 * i];
        if (xi < -1000000 || xi > 1000000 || yi < -1000000 || yi > 1000000) return -1.0e300;
        for (std::size_t j = 0; j < i; ++j) if (values[2 + 2 * j] == xi) return -1.0e300;
        x[i] = static_cast<double>(xi); p[i] = static_cast<double>(yi);
    }
    const double target = static_cast<double>(target_i);
    for (std::size_t k = 1; k < static_cast<std::size_t>(count); ++k)
        for (std::size_t i = 0; i < static_cast<std::size_t>(count) - k; ++i)
            p[i] = ((target - x[i + k]) * p[i] + (x[i] - target) * p[i + 1]) / (x[i] - x[i + k]);
    return p[0];
}
