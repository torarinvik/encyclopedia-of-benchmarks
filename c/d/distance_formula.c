/* Compute the Euclidean distance with the pinned Java coordinate expression. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double distance_formula(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    for (size_t i = 0; i < 4; ++i)
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
    const double dx = (double)(values[2] - values[0]);
    const double dy = (double)(values[3] - values[0]);
    return sqrt(dx * dx + dy * dy);
}
