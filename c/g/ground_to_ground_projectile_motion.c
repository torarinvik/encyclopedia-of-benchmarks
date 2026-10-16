/* Bounded selector adapter for the source projectile-motion formulas. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INPUT_SCALE INT64_C(1000000)
#define MAX_SPEED INT64_C(1000000000)
#define MAX_ANGLE INT64_C(360000000)
#define MIN_GRAVITY INT64_C(1000)
#define MAX_GRAVITY INT64_C(100000000)
#define MAX_TIME INT64_C(1000000000)
#define INVALID_RESULT (-1.0e300)
#define PI_VALUE 3.14159265358979323846264338327950288

double ground_to_ground_projectile_motion(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t operation = values[0], speed_value = values[1];
    const int64_t angle_value = values[2], auxiliary_value = values[3];
    if (operation < 0 || operation > 2 || speed_value < 0 || speed_value > MAX_SPEED ||
        angle_value < -MAX_ANGLE || angle_value > MAX_ANGLE) return INVALID_RESULT;
    if (operation == 1) {
        if (auxiliary_value < 0 || auxiliary_value > MAX_TIME) return INVALID_RESULT;
    } else if (auxiliary_value < MIN_GRAVITY || auxiliary_value > MAX_GRAVITY) {
        return INVALID_RESULT;
    }

    const double speed = (double)speed_value / (double)INPUT_SCALE;
    const double angle = (double)angle_value / (double)INPUT_SCALE;
    const double radians = angle * (PI_VALUE / 180.0);
    const double vertical_velocity = speed * sin(radians);
    if (operation == 0) {
        const double gravity = (double)auxiliary_value / (double)INPUT_SCALE;
        return 2.0 * vertical_velocity / gravity;
    }
    if (operation == 1) {
        const double time = (double)auxiliary_value / (double)INPUT_SCALE;
        return (speed * cos(radians)) * time;
    }
    const double gravity = (double)auxiliary_value / (double)INPUT_SCALE;
    return pow(vertical_velocity, 2.0) / (2.0 * gravity);
}
