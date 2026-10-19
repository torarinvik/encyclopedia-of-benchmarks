#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr double invalid_result = -1e300;
}

extern "C" double gesummv(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 1 || values[0] < 1 || values[0] > max_dimension)
        return invalid_result;
    const auto n = static_cast<std::size_t>(values[0]);
    double x[max_dimension];
    for (std::size_t i = 0; i < n; ++i) x[i] = static_cast<double>(i % n) / static_cast<double>(n);
    double result = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        double temporary = 0.0;
        double y = 0.0;
        for (std::size_t j = 0; j < n; ++j) {
            const double a = static_cast<double>((i * j + 1) % n) / static_cast<double>(n);
            const double b = static_cast<double>((i * j + 2) % n) / static_cast<double>(n);
            temporary = a * x[j] + temporary;
            y = b * x[j] + y;
        }
        y = 1.5 * temporary + 1.2 * y;
        result += y;
    }
    return result;
}
