/* Hooke's law restoring force: -spring_constant * displacement. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double hookes_law(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t spring_constant = values[0];
    const int64_t displacement = values[1];
    if (spring_constant < 1 || spring_constant > 1000 || displacement < -1000 || displacement > 1000)
        return INVALID_RESULT;
    return (-(double)spring_constant) * (double)displacement;
}
