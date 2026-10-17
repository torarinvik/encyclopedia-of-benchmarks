#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;

double integrand(double x)
{
    return (std::exp(x) / 2.0) * (std::cos(x) - std::sin(x));
}
}

extern "C" double rectangular_method(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 4) return invalid_result;
    const auto a_quarters = values[0], b_quarters = values[1];
    const auto intervals = values[2], rule = values[3];
    if (a_quarters < -64 || a_quarters >= b_quarters || b_quarters > 64 ||
        intervals < 1 || intervals > 64 ||
        (b_quarters - a_quarters) % intervals != 0 ||
        (rule != 0 && rule != 1)) return invalid_result;

    const double a = static_cast<double>(a_quarters) / 4.0;
    const double b = static_cast<double>(b_quarters) / 4.0;
    const double step = (b - a) / static_cast<double>(intervals);
    double x = a, total = 0.0;
    for (std::int64_t i = 0; i < intervals; ++i) {
        if (rule == 0) {
            total += integrand(x) * step;
            x += step;
        } else {
            x += step;
            total += integrand(x) * step;
        }
    }
    return total;
}
