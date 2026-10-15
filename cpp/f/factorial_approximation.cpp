#include <cmath>

extern "C" double factorial_approximation(double x) noexcept
{
    if (!(x >= 0.0 && x <= 170.0)) return -1.0;
    return std::sqrt(3.141592653589793) * std::pow(x / 2.718281828459045, x)
        * std::pow(8.0 * std::pow(x, 3.0) + 4.0 * std::pow(x, 2.0) + x + 1.0 / 30.0, 1.0 / 6.0);
}
