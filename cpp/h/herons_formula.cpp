#include <cmath>

namespace {
constexpr double SIDE_LIMIT = 1'000'000.0;
}

extern "C" double herons_formula(double a, double b, double c) noexcept
{
    if (a < 1.0 || a > SIDE_LIMIT || std::floor(a) != a ||
        b < 1.0 || b > SIDE_LIMIT || std::floor(b) != b ||
        c < 1.0 || c > SIDE_LIMIT || std::floor(c) != c ||
        a + b <= c || b + c <= a || c + a <= b) return -1.0;

    const double s = (a + b + c) / 2.0;
    return std::sqrt((s) * (s - a) * (s - b) * (s - c));
}

