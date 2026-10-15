/// RMS molecular speed: (3 * R * temperature / molar_mass) ** 0.5.
const std = @import("std");

export fn rms_speed_of_molecule(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const temperature = values[0];
    const molar_mass = values[1];
    if (temperature < 0 or temperature > 1000 or molar_mass < 1 or molar_mass > 1000)
        return -1.0e300;
    const numerator = (3.0 * 8.3144598) * @as(f64, @floatFromInt(temperature));
    return std.math.pow(f64, numerator / @as(f64, @floatFromInt(molar_mass)), 0.5);
}
