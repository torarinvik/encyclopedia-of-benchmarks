#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
double objective(double x) { return x * x - 3.0; }
}

extern "C" double secant(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 5 || values[0] != 0 ||
        values[1] < 1000000 || values[1] > 1500000 ||
        values[2] < 1600000 || values[2] > 2000000 || values[1] >= values[2] ||
        values[3] < 1 || values[3] > 100000 || values[4] < 0 || values[4] > 32) {
        return invalid_result;
    }
    double x0 = static_cast<double>(values[1]) / 1000000.0;
    double x1 = static_cast<double>(values[2]) / 1000000.0;
    const double tolerance = static_cast<double>(values[3]) / 1000000000.0;
    const auto max_updates = values[4];
    for (std::int64_t update = 0; update <= max_updates; ++update) {
        const double f1 = objective(x1);
        if (std::fabs(f1) <= tolerance) return x1;
        if (update == max_updates) break;
        const double f0 = objective(x0);
        const double denominator = f1 - f0;
        if (denominator == 0.0) return invalid_result;
        const double x2 = x1 - f1 * (x1 - x0) / denominator;
        if (!std::isfinite(x2)) return invalid_result;
        x0 = x1;
        x1 = x2;
    }
    return invalid_result;
}
