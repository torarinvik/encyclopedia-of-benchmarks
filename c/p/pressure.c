#include <math.h>

static double to_pascal_factor(double code)
{
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 1000.0;
    if (code == 2.0) return 1000000.0;
    if (code == 3.0) return 100000.0;
    if (code == 4.0) return 101325.0;
    if (code == 5.0) return 6894.757293168;
    return 0.0;
}

double pressure(double value, double from_unit_code, double to_unit_code)
{
    if (!isfinite(value) || value < -1000000.0 || value > 1000000.0) return -1.0;
    const double from_factor = to_pascal_factor(from_unit_code);
    const double to_factor = to_pascal_factor(to_unit_code);
    if (from_factor == 0.0 || to_factor == 0.0) return -1.0;
    const double pascals = value * from_factor;
    return pascals / to_factor;
}
