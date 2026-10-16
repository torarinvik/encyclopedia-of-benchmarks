const std = @import("std");

export fn projectile_motion(values: [*c]const f64, length: usize,
    output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    for (0..4) |i| {
        if (!std.math.isFinite(values[i])) return -1;
    }

    const velocity = values[0];
    const angle_degrees = values[1];
    const height = values[2];
    const gravity = values[3];
    if (velocity < 0.0 or velocity > 1000.0 or
        angle_degrees < -180.0 or angle_degrees > 180.0 or
        height < 0.0 or height > 1000.0 or gravity < 0.1 or gravity > 20.0) return -1;

    const angle_radians = angle_degrees / 180.0 * 3.14159265358979323846;
    const initial_vertical_velocity = velocity * @sin(angle_radians);
    const initial_horizontal_velocity = velocity * @cos(angle_radians);
    const total_time_of_flight = (initial_vertical_velocity +
        @sqrt(initial_vertical_velocity * initial_vertical_velocity + 2.0 * gravity * height)) / gravity;
    var maximum_height = height;
    if (initial_vertical_velocity > 0.0) {
        const height_gained = initial_vertical_velocity * initial_vertical_velocity / (2.0 * gravity);
        maximum_height = height + height_gained;
    }
    const horizontal_range = initial_horizontal_velocity * total_time_of_flight;

    if (output == null or capacity < 3) return -2;
    output[0] = total_time_of_flight;
    output[1] = horizontal_range;
    output[2] = maximum_height;
    return 3;
}
