#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COORDINATE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double distance_between_two_points(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    for (size_t index = 0; index < 4; ++index) {
        if (values[index] < -MAX_COORDINATE || values[index] > MAX_COORDINATE) return INVALID_RESULT;
    }
    const double dx = (double)(values[2] - values[0]);
    const double dy = (double)(values[3] - values[1]);
    return sqrt(dx * dx + dy * dy);
}
