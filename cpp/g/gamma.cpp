#include <cmath>

namespace {
constexpr double invalid_result = -1.0e300;

double gamma_recursive_impl(double num) {
    if (num == 0.5) return std::sqrt(3.14159265358979323846);
    if (num == 1.0) return 1.0;
    return (num - 1.0) * gamma_recursive_impl(num - 1.0);
}
}

extern "C" double gamma_recursive(double num) noexcept {
    if (!(num >= 0.5 && num <= 20.0) || num * 2.0 != std::trunc(num * 2.0)) return invalid_result;
    return gamma_recursive_impl(num);
}
