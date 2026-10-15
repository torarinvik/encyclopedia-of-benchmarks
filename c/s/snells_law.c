#include <math.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.141592653589793238462643383279502884

static double round_two_even(double value)
{
    const double scaled = value * 100.0;
    const double lower = floor(scaled);
    const double fraction = scaled - lower;
    int64_t rounded = (int64_t)lower;
    if (fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0)) ++rounded;
    return (double)rounded / 100.0;
}

double snells_law(double n1, double n2, double incident_angle_degrees)
{
    if (!(n1 >= 0.5 && n1 <= 2.5) || !(n2 >= 0.5 && n2 <= 2.5) ||
        !(incident_angle_degrees >= -90.0 && incident_angle_degrees <= 90.0)) return INVALID_RESULT;
    const double incident_angle_radians = incident_angle_degrees * (PI / 180.0);
    const double refraction_sine = (n1 / n2) * sin(incident_angle_radians);
    const double scale = fmax(fabs(refraction_sine), 1.0);
    if (fabs(refraction_sine - 1.0) <= 1.0e-9 * scale) return 90.0;
    if (fabs(refraction_sine + 1.0) <= 1.0e-9 * scale) return -90.0;
    if (!(refraction_sine >= -1.0 && refraction_sine <= 1.0)) return INVALID_RESULT;
    const double refraction_angle_degrees = asin(refraction_sine) * (180.0 / PI);
    return round_two_even(refraction_angle_degrees);
}
