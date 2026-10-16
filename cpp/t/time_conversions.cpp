/* Convert time with the pinned Python source's factors and three-place rounding. */
#include <cmath>

namespace {
double seconds_factor(double code)
{
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 60.0;
    if (code == 2.0) return 3600.0;
    if (code == 3.0) return 86400.0;
    if (code == 4.0) return 604800.0;
    if (code == 5.0) return 2629800.0;
    if (code == 6.0) return 31557600.0;
    return 0.0;
}

double inverse_factor(double code)
{
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 0.016666666666666666;
    if (code == 2.0) return 0.0002777777777777778;
    if (code == 3.0) return 0.000011574074074074073;
    if (code == 4.0) return 0.0000016534391534391535;
    if (code == 5.0) return 0.0000003802570537683474;
    if (code == 6.0) return 0.00000003168808781402895;
    return 0.0;
}

double round_three_ties_even(double value)
{
    const double scaled = value * 1000.0;
    const double lower = std::floor(scaled);
    const double fraction = scaled - lower;
    const double residual = std::fma(value, 1000.0, -scaled);
    double rounded = lower;
    if (fraction > 0.5 || (fraction == 0.5 && (residual > 0.0
        || (residual == 0.0 && std::fmod(lower, 2.0) != 0.0)))) rounded = lower + 1.0;
    return rounded / 1000.0;
}
}

extern "C" double time_conversions(double time_value, double from_code, double to_code)
{
    if (!std::isfinite(time_value) || time_value < 0.0 || time_value > 10000.0) return -1e300;
    const double source = seconds_factor(from_code);
    const double inverse = inverse_factor(to_code);
    if (source == 0.0 || inverse == 0.0) return -1e300;
    const double scaled = time_value * source;
    return round_three_ties_even(scaled * inverse);
}
