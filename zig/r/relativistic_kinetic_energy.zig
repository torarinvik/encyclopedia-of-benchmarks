const std = @import("std");

const SPEED_OF_LIGHT: i64 = 299792458;
const INVALID_RESULT: f64 = -1.0e300;

export fn relativistic_kinetic_energy(values: [*]const i64, length: usize) f64 {
    if (length != 2) return INVALID_RESULT;
    const mass = values[0];
    const velocity = values[1];
    if (mass < 0 or mass > 1_000_000 or velocity < -(SPEED_OF_LIGHT - 1) or velocity > SPEED_OF_LIGHT - 1)
        return INVALID_RESULT;
    const c_squared = SPEED_OF_LIGHT * SPEED_OF_LIGHT;
    const gamma = 1.0 / @sqrt(1.0 - @as(f64, @floatFromInt(velocity * velocity)) /
        @as(f64, @floatFromInt(c_squared)));
    return (gamma - 1.0) * @as(f64, @floatFromInt(mass)) * @as(f64, @floatFromInt(c_squared));
}
