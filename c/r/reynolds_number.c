/* Reynolds number: density * abs(velocity) * diameter / viscosity. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double reynolds_number(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t density = values[0];
    const int64_t velocity = values[1];
    const int64_t diameter = values[2];
    const int64_t viscosity = values[3];
    if (density < 1 || density > 1000 || velocity < -1000 || velocity > 1000 ||
        diameter < 1 || diameter > 1000 || viscosity < 1 || viscosity > 1000)
        return INVALID_RESULT;
    const int64_t speed = velocity < 0 ? -velocity : velocity;
    return (((double)density * (double)speed) * (double)diameter) / (double)viscosity;
}
