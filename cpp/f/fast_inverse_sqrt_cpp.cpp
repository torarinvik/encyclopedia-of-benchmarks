#include <cmath>
#include <cstdint>
#include <cstring>

namespace {
constexpr double MIN_VALUE = 1e-6;
constexpr double MAX_VALUE = 1e6;
}

extern "C" double fast_inverse_sqrt_cpp(double value) noexcept
{
    if (!std::isfinite(value) || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    double y = value;
    const double x2 = y * 0.5;
    std::int64_t bits;
    std::memcpy(&bits, &y, sizeof(bits));
    bits = INT64_C(0x5fe6eb50c7b537a9) - (bits >> 1);
    std::memcpy(&y, &bits, sizeof(y));
    y = y * (1.5 - (x2 * y * y));
    y = y * (1.5 - (x2 * y * y));
    return y;
}
