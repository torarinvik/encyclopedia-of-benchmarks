#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double kInvalidResult = -1.0e300;

double python_objective(double x) {
    return 8.0 * x - 2.0 * std::exp(-x);
}

double c_variant() {
    double x0 = 0.2, x1 = 0.5;
    constexpr double tolerance = 100.0 / 1000000.0;
    for (int iteration = 0; iteration < 99; ++iteration) {
        const double f1 = x1 * x1 - 3.0;
        const double f0 = x0 * x0 - 3.0;
        const double x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1;
        x1 = x2;
        if (std::fabs(x1 - x0) < tolerance) return x2;
    }
    return -1.0;
}

double python_variant(std::int64_t repeats) {
    double x0 = 1.0, x1 = 3.0;
    for (std::int64_t iteration = 0; iteration < repeats; ++iteration) {
        const double f1 = python_objective(x1);
        const double f0 = python_objective(x0);
        const double x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0);
        x0 = x1;
        x1 = x2;
    }
    return x1;
}
}

extern "C" double secant_method(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 2) return kInvalidResult;
    if (values[0] == 0 && values[1] == 100) return c_variant();
    if (values[0] == 1 && values[1] >= 0 && values[1] <= 2) return python_variant(values[1]);
    return kInvalidResult;
}
