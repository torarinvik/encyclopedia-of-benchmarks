#include <cmath>

extern "C" double cos(double x) noexcept
{
    if (!(x >= -1000000.0 && x <= 1000000.0)) return -1.0;
    const double tp = 1.0 / (2.0 * 3.141592653589793);
    x *= tp;
    x -= 0.25 + std::floor(x + 0.25);
    x *= 16.0 * (std::abs(x) - 0.5);
    x += 0.225 * x * (std::abs(x) - 1.0);
    return x;
}
