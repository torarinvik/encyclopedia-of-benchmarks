module projectile_motion;

extern fn double sqrt(double value);
extern fn double sin(double value);
extern fn double cos(double value);

const double PI = 3.14159265358979323846;

fn long projectile_motion(double* values, usz length,
                          double* output, usz capacity) @export("projectile_motion") {
    if (values == null || length != 4) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100) return -1;
    }

    double velocity = values[0];
    double angle_degrees = values[1];
    double height = values[2];
    double gravity = values[3];
    if (velocity < 0.0 || velocity > 1000.0 ||
        angle_degrees < -180.0 || angle_degrees > 180.0 ||
        height < 0.0 || height > 1000.0 || gravity < 0.1 || gravity > 20.0) return -1;

    double angle_radians = angle_degrees / 180.0 * PI;
    double initial_vertical_velocity = velocity * sin(angle_radians);
    double initial_horizontal_velocity = velocity * cos(angle_radians);
    double total_time_of_flight = (initial_vertical_velocity +
        sqrt(initial_vertical_velocity * initial_vertical_velocity + 2.0 * gravity * height)) / gravity;
    double maximum_height = height;
    if (initial_vertical_velocity > 0.0) {
        double height_gained = initial_vertical_velocity * initial_vertical_velocity / (2.0 * gravity);
        maximum_height = height + height_gained;
    }
    double horizontal_range = initial_horizontal_velocity * total_time_of_flight;

    if (output == null || capacity < 3) return -2;
    output[0] = total_time_of_flight;
    output[1] = horizontal_range;
    output[2] = maximum_height;
    return 3;
}
