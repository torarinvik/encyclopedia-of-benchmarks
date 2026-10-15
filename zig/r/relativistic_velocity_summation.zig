const std = @import("std");

const SPEED_OF_LIGHT: i64 = 299792458;
const INVALID_RESULT: f64 = -1.0e300;

export fn relativistic_velocity_summation(values: [*]const i64, length: usize) f64 {
    if (length != 2) return INVALID_RESULT;
    const object_velocity = values[0];
    const frame_velocity = values[1];
    if (object_velocity < -SPEED_OF_LIGHT or object_velocity > SPEED_OF_LIGHT or
        frame_velocity < -(SPEED_OF_LIGHT - 1) or frame_velocity > SPEED_OF_LIGHT - 1)
    {
        return INVALID_RESULT;
    }
    const numerator = object_velocity + frame_velocity;
    const c_squared = SPEED_OF_LIGHT * SPEED_OF_LIGHT;
    const denominator = 1.0 + @as(f64, @floatFromInt(object_velocity * frame_velocity)) /
        @as(f64, @floatFromInt(c_squared));
    return @as(f64, @floatFromInt(numerator)) / denominator;
}
