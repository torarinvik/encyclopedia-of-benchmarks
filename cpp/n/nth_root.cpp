#include <cmath>

namespace {
constexpr double invalid_result = -1.0e300;
}

extern "C" double nth_root(double radicand, double index, double tolerance) noexcept
{
    if (!std::isfinite(radicand) || !std::isfinite(index) || !std::isfinite(tolerance) ||
        radicand < 0.5 || radicand > 1000.0 || index < 3.0 || index > 8.0 ||
        index != std::floor(index) || tolerance < 1.0e-12 || tolerance > 1.0e-3) return invalid_result;
    double new_approximation = radicand;
    double old_approximation = new_approximation + tolerance + 0.1;
    while (tolerance <= std::abs(old_approximation - new_approximation)) {
        old_approximation = new_approximation;
        const double first_summand = (index - 1.0) / index * old_approximation;
        const double second_summand = radicand / (index * std::pow(old_approximation, index - 1.0));
        new_approximation = first_summand + second_summand;
    }
    return new_approximation;
}
