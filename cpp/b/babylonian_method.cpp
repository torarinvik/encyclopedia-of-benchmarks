// Preserve the bounded non-square path of the pinned C++ Babylonian method.
#include <cstdint>

extern "C" double babylonian_method(double input) noexcept
{
    if (!(input >= 2.0 && input <= 999999.0)) return -1.0;
    const auto radicand = static_cast<std::int64_t>(input);
    if (static_cast<double>(radicand) != input) return -1.0;
    std::int64_t i = 1;
    while (i * i <= radicand) ++i;
    --i;
    if (i * i == radicand) return -1.0;
    const double x0 = static_cast<double>(i);
    return (input / x0 + x0) / 2.0;
}
