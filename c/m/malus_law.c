/* Malus's law: I0 * cos(radians(angle))^2. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.141592653589793238462643383279502884

double malus_law(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t initial_intensity = values[0];
    const int64_t angle = values[1];
    if (initial_intensity < 0 || initial_intensity > 1000 || angle < 0 || angle > 360)
        return INVALID_RESULT;
    const double radians = ((double)angle * PI) / 180.0;
    const double cosine = cos(radians);
    return (double)initial_intensity * (cosine * cosine);
}
