/* Mass-energy equivalence, with an operation selector for both source APIs. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SPEED_OF_LIGHT 299792458.0
#define SPEED_OF_LIGHT_SQUARED (SPEED_OF_LIGHT * SPEED_OF_LIGHT)

double mass_energy_equivalence(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t operation = values[0], value = values[1];
    if ((operation != 0 && operation != 1) || value < 0 || value > INT64_C(1000000000)) return INVALID_RESULT;
    if (operation == 0) return (double)value * SPEED_OF_LIGHT_SQUARED;
    return (double)value / SPEED_OF_LIGHT_SQUARED;
}
