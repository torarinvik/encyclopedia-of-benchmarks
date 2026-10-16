#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t COEFFICIENT_LIMIT = 1'000'000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double quadratic_equation_solver_complex_roots(
    const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    const std::int64_t a = values[0], b = values[1], c = values[2], component = values[3];
    if (a == 0 || a < -COEFFICIENT_LIMIT || a > COEFFICIENT_LIMIT ||
        b < -COEFFICIENT_LIMIT || b > COEFFICIENT_LIMIT ||
        c < -COEFFICIENT_LIMIT || c > COEFFICIENT_LIMIT ||
        component < 0 || component > 3) return INVALID_RESULT;

    const std::int64_t discriminant = b * b - 4 * a * c;
    const double denominator = 2.0 * static_cast<double>(a);
    if (discriminant > 0) {
        if (component >= 2) return INVALID_RESULT;
        const double square_root = std::sqrt(static_cast<double>(discriminant));
        if (component == 0) return (-static_cast<double>(b) + square_root) / denominator;
        return (-static_cast<double>(b) - square_root) / denominator;
    }
    if (discriminant == 0) {
        return component == 0 ? -static_cast<double>(b) / denominator : INVALID_RESULT;
    }

    if (component < 2) return -static_cast<double>(b) / denominator;
    const double imaginary = std::sqrt(static_cast<double>(-discriminant)) / denominator;
    return component == 2 ? imaginary : -imaginary;
}
