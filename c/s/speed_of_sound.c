/* Speed of sound in a fluid: (bulk modulus / density) ** 0.5. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double speed_of_sound(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t density = values[0];
    const int64_t bulk_modulus = values[1];
    if (density < 1 || density > 1000 || bulk_modulus < 1 || bulk_modulus > 1000000000)
        return INVALID_RESULT;
    return pow((double)bulk_modulus / (double)density, 0.5);
}
