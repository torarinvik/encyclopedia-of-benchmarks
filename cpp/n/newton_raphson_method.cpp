#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
double equation(double x) { return std::pow(x, 3.0) - (4.0 * x) - 9.0; }
double derivative(double x) { return 3.0 * std::pow(x, 2.0) - 4.0; }
}

extern "C" double newton_raphson_method(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 2) return invalid_result;
    const auto initial_milli = values[0], iteration_limit = values[1];
    if (initial_milli < 2000 || initial_milli > 4000 || iteration_limit < 1 || iteration_limit > 32)
        return invalid_result;
    double c = static_cast<double>(initial_milli) / 1000.0;
    double z = c;
    for (std::int64_t iteration = 0; iteration < iteration_limit; ++iteration) {
        const double m = equation(c);
        const double n = derivative(c);
        z = c - (m / n);
        c = z;
        if (std::abs(m) < 1e-10) break;
    }
    return z;
}
