const std = @import("std");

const INPUT_SCALE: i64 = 1_000_000;
const MAX_SPEED: i64 = 1_000_000_000;
const MAX_ANGLE: i64 = 360_000_000;
const MIN_GRAVITY: i64 = 1_000;
const MAX_GRAVITY: i64 = 100_000_000;
const MAX_TIME: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

export fn ground_to_ground_projectile_motion(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const operation = values[0];
    const speed_value = values[1];
    const angle_value = values[2];
    const auxiliary_value = values[3];
    if (operation < 0 or operation > 2 or speed_value < 0 or speed_value > MAX_SPEED or
        angle_value < -MAX_ANGLE or angle_value > MAX_ANGLE) return INVALID_RESULT;
    if (operation == 1) {
        if (auxiliary_value < 0 or auxiliary_value > MAX_TIME) return INVALID_RESULT;
    } else if (auxiliary_value < MIN_GRAVITY or auxiliary_value > MAX_GRAVITY) {
        return INVALID_RESULT;
    }

    const speed = @as(f64, @floatFromInt(speed_value)) / @as(f64, @floatFromInt(INPUT_SCALE));
    const angle = @as(f64, @floatFromInt(angle_value)) / @as(f64, @floatFromInt(INPUT_SCALE));
    const radians = angle * (PI_VALUE / 180.0);
    const vertical_velocity = speed * @sin(radians);
    if (operation == 0) {
        const gravity = @as(f64, @floatFromInt(auxiliary_value)) / @as(f64, @floatFromInt(INPUT_SCALE));
        return 2.0 * vertical_velocity / gravity;
    }
    if (operation == 1) {
        const time = @as(f64, @floatFromInt(auxiliary_value)) / @as(f64, @floatFromInt(INPUT_SCALE));
        return (speed * @cos(radians)) * time;
    }
    const gravity = @as(f64, @floatFromInt(auxiliary_value)) / @as(f64, @floatFromInt(INPUT_SCALE));
    return std.math.pow(f64, vertical_velocity, 2.0) / (2.0 * gravity);
}
