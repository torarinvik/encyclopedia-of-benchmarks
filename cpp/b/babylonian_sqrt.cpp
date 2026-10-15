// Babylonian square root using the pinned Julia defaults.
#include <cmath>

extern "C" double babylonian_sqrt(double input) noexcept
{
    if (!(input >= 0.0 && input <= 1000000.0)) return -1.0;
    double estimate = input / 2.0;
    constexpr double tolerance = 0.000001;
    while (tolerance <= std::abs(estimate * estimate - input)) {
        estimate = 0.5 * (estimate + input / estimate);
    }
    return estimate;
}
