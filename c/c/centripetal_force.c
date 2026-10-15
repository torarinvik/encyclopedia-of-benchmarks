/* Centripetal force: (mass * velocity^2) / radius. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double centripetal_force(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t mass = values[0];
    const int64_t velocity = values[1];
    const int64_t radius = values[2];
    if (mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 || radius < 1 || radius > 1000)
        return INVALID_RESULT;
    const double velocity_squared = (double)velocity * (double)velocity;
    return ((double)mass * velocity_squared) / (double)radius;
}
