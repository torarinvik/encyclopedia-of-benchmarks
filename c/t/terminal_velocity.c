/* Terminal velocity with standard gravity and bounded positive inputs. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double terminal_velocity(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t mass = values[0];
    const int64_t density = values[1];
    const int64_t area = values[2];
    const int64_t drag_coefficient = values[3];
    if (mass < 1 || mass > 1000 || density < 1 || density > 1000 || area < 1 || area > 1000 ||
        drag_coefficient < 1 || drag_coefficient > 1000)
        return INVALID_RESULT;
    const double numerator = (2.0 * (double)mass) * 9.80665;
    const double denominator = ((double)density * (double)area) * (double)drag_coefficient;
    return sqrt(numerator / denominator);
}
