#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SPEED_OF_LIGHT INT64_C(299792458)

double relativistic_kinetic_energy(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t mass = values[0];
    const int64_t velocity = values[1];
    if (mass < 0 || mass > 1000000 || velocity < -(SPEED_OF_LIGHT - 1) || velocity > SPEED_OF_LIGHT - 1)
        return INVALID_RESULT;
    const double gamma = 1.0 / sqrt(1.0 - ((double)(velocity * velocity) / (double)(SPEED_OF_LIGHT * SPEED_OF_LIGHT)));
    return (gamma - 1.0) * (double)mass * (double)(SPEED_OF_LIGHT * SPEED_OF_LIGHT);
}
