#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::int64_t max_endpoint_micro = 10000000;

double integrand(double x)
{
    return std::exp(-x) * (4.0 - std::pow(x, 2.0));
}
}

extern "C" double simpson_integration(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 3) return invalid_result;
    const auto intervals = values[0], a_micro = values[1], b_micro = values[2];
    if (intervals < 2 || intervals > 128 || intervals % 2 != 0 ||
        a_micro < -max_endpoint_micro || a_micro > max_endpoint_micro ||
        b_micro < -max_endpoint_micro || b_micro > max_endpoint_micro || a_micro > b_micro) {
        return invalid_result;
    }
    const double a = static_cast<double>(a_micro) / 1000000.0;
    const double b = static_cast<double>(b_micro) / 1000000.0;
    if (a == b) return 0.0;
    const double h = (b - a) / static_cast<double>(intervals);
    double xi = a, total = 0.0;
    for (std::int64_t i = 0; i <= intervals; ++i) {
        const double sample = integrand(xi);
        if (i == 0 || i == intervals) total += sample;
        else if (i % 2 != 0) total += 4.0 * sample;
        else total += 2.0 * sample;
        xi += h;
    }
    return (h / 3.0) * total;
}
