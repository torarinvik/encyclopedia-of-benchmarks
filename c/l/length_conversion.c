/* Convert bounded lengths between millimeters, centimeters, meters, and kilometers. */
#include <stdint.h>

static double meters_per_unit(int unit)
{
    switch (unit) {
        case 0: return 0.001;
        case 1: return 0.01;
        case 2: return 1.0;
        default: return 1000.0;
    }
}

double length_conversion(double value, double from_unit_input, double to_unit_input)
{
    if (value != value || value < -1000000.0 || value > 1000000.0) return -1e300;
    if (!((from_unit_input == 0.0) || (from_unit_input == 1.0) ||
          (from_unit_input == 2.0) || (from_unit_input == 3.0)) ||
        !((to_unit_input == 0.0) || (to_unit_input == 1.0) ||
          (to_unit_input == 2.0) || (to_unit_input == 3.0))) return -1e300;
    const int from_unit = (int)from_unit_input;
    const int to_unit = (int)to_unit_input;
    return (value * meters_per_unit(from_unit)) / meters_per_unit(to_unit);
}
