#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SPEED_OF_LIGHT INT64_C(299792458)

double relativistic_velocity_summation(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t object_velocity = values[0];
    const int64_t frame_velocity = values[1];
    if (object_velocity < -SPEED_OF_LIGHT || object_velocity > SPEED_OF_LIGHT ||
        frame_velocity < -(SPEED_OF_LIGHT - 1) || frame_velocity > SPEED_OF_LIGHT - 1)
        return INVALID_RESULT;
    const int64_t numerator = object_velocity + frame_velocity;
    const double denominator = 1.0 + (double)(object_velocity * frame_velocity) /
        (double)(SPEED_OF_LIGHT * SPEED_OF_LIGHT);
    return (double)numerator / denominator;
}
