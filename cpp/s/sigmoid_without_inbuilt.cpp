#include <cmath>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double sigmoid_without_inbuilt(double x, double slope) noexcept {
    if (!std::isfinite(x) || !std::isfinite(slope) || x < -10.0 || x > 10.0 ||
        slope < -10.0 || slope > 10.0) return INVALID_RESULT;
    return 1.0 / (1.0 + std::exp(-slope * x));
}

