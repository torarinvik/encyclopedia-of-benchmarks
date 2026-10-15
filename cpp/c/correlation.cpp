#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double delta = 1.0e-9;
constexpr std::int64_t max_n = 128;
}

extern "C" double correlation(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3) return invalid_result;
    const std::int64_t n_value = values[0];
    if (n_value < 1 || n_value > max_n || length != 1 + 2 * static_cast<std::size_t>(n_value)) return invalid_result;
    const std::size_t n = static_cast<std::size_t>(n_value);
    double exy = 0.0, ex = 0.0, exx = 0.0, ey = 0.0, eyy = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t xi = values[1 + i], yi = values[1 + n + i];
        if (xi < -1000 || xi > 1000 || yi < -1000 || yi > 1000) return invalid_result;
        const double x = static_cast<double>(xi), y = static_cast<double>(yi);
        exy += x * y;
        ex += x;
        exx += x * x;
        ey += y;
        eyy += y * y;
    }
    exy /= static_cast<double>(n);
    ex /= static_cast<double>(n);
    exx /= static_cast<double>(n);
    ey /= static_cast<double>(n);
    eyy /= static_cast<double>(n);
    const double cov = exy - ex * ey;
    const double varx = std::sqrt(exx - ex * ex);
    const double vary = std::sqrt(eyy - ey * ey);
    if (varx * vary < delta) return 0.0;
    return cov / std::sqrt(varx * vary);
}
