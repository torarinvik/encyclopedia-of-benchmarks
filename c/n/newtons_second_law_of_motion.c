/* Newton's second law: net force equals mass times acceleration. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double newtons_second_law_of_motion(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t mass = values[0];
    const int64_t acceleration = values[1];
    if (mass < -1000 || mass > 1000 || acceleration < -1000 || acceleration > 1000)
        return INVALID_RESULT;
    return (double)mass * (double)acceleration;
}
