/* Classical kinetic energy: 0.5 * mass * abs(velocity)^2. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double kinetic_energy(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t mass = values[0];
    const int64_t velocity = values[1];
    if (mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000)
        return INVALID_RESULT;
    const int64_t speed = velocity < 0 ? -velocity : velocity;
    return ((0.5 * (double)mass) * (double)speed) * (double)speed;
}
