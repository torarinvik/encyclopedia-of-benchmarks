#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;

double integrand(std::int64_t function_id, double x)
{
    switch (function_id) {
    case 0: return std::sqrt(x) + std::log(x);
    case 1: return std::exp(-x) * (4.0 - std::pow(x, 2.0));
    case 2: return std::sqrt(2.0 * std::pow(x, 3.0) + 3.0);
    case 3: return x + std::log(2.0 * x + 1.0);
    default: return invalid_result;
    }
}
}

extern "C" double midpoint_integral_method(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 4) return invalid_result;
    const auto function_id = values[0], intervals = values[1];
    const auto a_milli = values[2], b_milli = values[3];
    if (function_id < 0 || function_id > 3 || intervals < 2 || intervals > 64 || intervals % 2 != 0 ||
        a_milli < 0 || a_milli >= b_milli || b_milli > 10000) return invalid_result;
    const double a = static_cast<double>(a_milli) / 1000.0;
    const double b = static_cast<double>(b_milli) / 1000.0;
    const double h = (b - a) / static_cast<double>(intervals);
    double xi = a, sum = 0.0;
    for (std::int64_t i = 0; i < intervals; ++i) {
        sum += integrand(function_id, xi + h / 2.0);
        xi += h;
    }
    return sum * h;
}
