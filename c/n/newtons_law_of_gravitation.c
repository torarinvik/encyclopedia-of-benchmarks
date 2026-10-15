/* Solve Newton's law of gravitation for one missing parameter. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define GRAVITATIONAL_CONSTANT 6.6743e-11

double newtons_law_of_gravitation(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t target = values[0], a = values[1], b = values[2], c = values[3];
    if (target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c < 1 || c > 1000)
        return INVALID_RESULT;
    switch (target) {
        case 0: return GRAVITATIONAL_CONSTANT * ((double)a * (double)b) / ((double)c * (double)c);
        case 1: return (double)a * ((double)c * (double)c) / (GRAVITATIONAL_CONSTANT * (double)b);
        case 2: return (double)a * ((double)c * (double)c) / (GRAVITATIONAL_CONSTANT * (double)b);
        default: return sqrt((GRAVITATIONAL_CONSTANT * ((double)b * (double)c)) / (double)a);
    }
}
