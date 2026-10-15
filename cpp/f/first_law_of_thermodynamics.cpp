// Numeric first-law operations over a bounded integer-valued domain.
#include <cmath>

namespace { constexpr double invalid_result = -1e300; }

extern "C" double first_law_of_thermodynamics(double operation, double a, double b) noexcept {
    if (!std::isfinite(operation) || !std::isfinite(a) || !std::isfinite(b) ||
        operation < 0.0 || operation > 2.0 || operation != std::trunc(operation) ||
        a < -1000000.0 || a > 1000000.0 || b < -1000000.0 || b > 1000000.0 ||
        a != std::trunc(a) || b != std::trunc(b)) return invalid_result;
    if (operation == 0.0) return a - b;
    if (operation == 1.0) return a + b;
    return a - b;
}
