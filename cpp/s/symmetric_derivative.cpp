#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_x_nanounits = -6300000000LL;
constexpr std::int64_t max_x_nanounits = 6300000000LL;
constexpr double default_step = 1.0e-10;
constexpr double invalid_result = -1.0e300;
}

extern "C" double symmetric_derivative(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t function_id = values[0], x_nanounits = values[1];
    if ((function_id != 0 && function_id != 1) ||
        x_nanounits < min_x_nanounits || x_nanounits > max_x_nanounits) return invalid_result;

    const double x = static_cast<double>(x_nanounits) / 1000000000.0;
    const double upper = function_id == 0 ? std::sin(x + default_step) : std::exp(x + default_step);
    const double lower = function_id == 0 ? std::sin(x - default_step) : std::exp(x - default_step);
    return (upper - lower) / (2.0 * default_step);
}
