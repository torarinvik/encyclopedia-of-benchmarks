/* Preserve the bounded non-square path of the pinned C++ Babylonian method. */
#include <stdint.h>

double babylonian_method(double input)
{
    if (!(input >= 2.0 && input <= 999999.0)) return -1.0;
    const int64_t radicand = (int64_t)input;
    if ((double)radicand != input) return -1.0;
    int64_t i = 1;
    while (i * i <= radicand) ++i;
    --i;
    if (i * i == radicand) return -1.0;
    const double x0 = (double)i;
    return (input / x0 + x0) / 2.0;
}
