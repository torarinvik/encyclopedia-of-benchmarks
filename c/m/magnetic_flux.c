/* Magnetic flux rounded to one decimal place. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define PI_VALUE 3.14159265358979323846

double magnetic_flux(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t magnetic_field = values[0];
    const int64_t area = values[1];
    const int64_t angle = values[2];
    if (magnetic_field < 0 || magnetic_field > 10000 || area < 0 || area > 10000 ||
        (angle != 0 && angle != 60 && angle != 90 && angle != 120 && angle != 180))
        return INVALID_RESULT;
    const double radians = (double)angle * (PI_VALUE / 180.0);
    const double flux = (double)magnetic_field * (double)area * cos(radians);
    return round(flux * 10.0) / 10.0;
}
