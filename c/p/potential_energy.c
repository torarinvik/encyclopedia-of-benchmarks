/* Gravitational potential energy: mass * standard gravity * height. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double potential_energy(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t mass = values[0];
    const int64_t height = values[1];
    if (mass < 0 || mass > 1000 || height < 0 || height > 1000)
        return INVALID_RESULT;
    return ((double)mass * 9.80665) * (double)height;
}
