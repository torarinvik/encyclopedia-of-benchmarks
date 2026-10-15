/// Real/reactive power from apparent power and power factor.
const std = @import("std");

export fn real_and_reactive_power(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const operation = values[0];
    const apparent_power = values[1];
    const factor_units = values[2];
    if ((operation != 0 and operation != 1) or apparent_power < -1_000_000_000 or
        apparent_power > 1_000_000_000 or factor_units < -10_000 or factor_units > 10_000)
        return -1.0e300;
    const power_factor = @as(f64, @floatFromInt(factor_units)) / 10_000.0;
    if (operation == 0) return @as(f64, @floatFromInt(apparent_power)) * power_factor;
    return @as(f64, @floatFromInt(apparent_power)) * @sqrt(1.0 - std.math.pow(f64, power_factor, 2.0));
}
