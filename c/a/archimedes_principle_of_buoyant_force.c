/* Buoyant force: fluid density * gravity * displaced volume. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double archimedes_principle_of_buoyant_force(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t fluid_density = values[0];
    const int64_t volume = values[1];
    if (fluid_density < 1 || fluid_density > 1000 || volume < 1 || volume > 1000)
        return INVALID_RESULT;
    return ((double)fluid_density * 9.80665) * (double)volume;
}
