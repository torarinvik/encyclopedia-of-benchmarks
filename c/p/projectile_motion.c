#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846

int64_t projectile_motion(const double *values, size_t length,
                          double *output, size_t capacity) {
    if (values == NULL || length != 4) return -1;
    for (size_t i = 0; i < length; ++i)
        if (!isfinite(values[i])) return -1;

    const double velocity = values[0];
    const double angle_degrees = values[1];
    const double height = values[2];
    const double gravity = values[3];
    if (velocity < 0.0 || velocity > 1000.0 ||
        angle_degrees < -180.0 || angle_degrees > 180.0 ||
        height < 0.0 || height > 1000.0 ||
        gravity < 0.1 || gravity > 20.0) return -1;

    const double angle_radians = angle_degrees / 180.0 * PI;
    const double initial_vertical_velocity = velocity * sin(angle_radians);
    const double initial_horizontal_velocity = velocity * cos(angle_radians);
    const double total_time_of_flight =
        (initial_vertical_velocity +
         sqrt(initial_vertical_velocity * initial_vertical_velocity +
              2.0 * gravity * height)) / gravity;
    double maximum_height;
    if (initial_vertical_velocity > 0.0) {
        const double height_gained =
            initial_vertical_velocity * initial_vertical_velocity / (2.0 * gravity);
        maximum_height = height + height_gained;
    } else {
        maximum_height = height;
    }
    const double horizontal_range = initial_horizontal_velocity * total_time_of_flight;

    if (output == NULL || capacity < 3) return -2;
    output[0] = total_time_of_flight;
    output[1] = horizontal_range;
    output[2] = maximum_height;
    return 3;
}
