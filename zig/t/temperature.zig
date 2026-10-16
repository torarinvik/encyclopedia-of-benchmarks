const std = @import("std");

fn validUnit(unit: f64) bool {
    return unit == 0.0 or unit == 1.0 or unit == 2.0 or unit == 3.0 or
        unit == 4.0 or unit == 5.0 or unit == 6.0 or unit == 7.0;
}

fn toKelvin(value: f64, unit: f64) f64 {
    if (unit == 0.0) return value;
    if (unit == 1.0) return value + 273.15;
    if (unit == 2.0) return (value + 459.67) * 5.0 / 9.0;
    if (unit == 3.0) return value * 5.0 / 9.0;
    if (unit == 4.0) return 373.15 - value * 2.0 / 3.0;
    if (unit == 5.0) return value * 100.0 / 33.0 + 273.15;
    if (unit == 6.0) return value * 5.0 / 4.0 + 273.15;
    return (value - 7.5) * 40.0 / 21.0 + 273.15;
}

fn fromKelvin(kelvin: f64, unit: f64) f64 {
    if (unit == 0.0) return kelvin;
    if (unit == 1.0) return kelvin - 273.15;
    if (unit == 2.0) return kelvin * 9.0 / 5.0 - 459.67;
    if (unit == 3.0) return kelvin * 9.0 / 5.0;
    if (unit == 4.0) return (373.15 - kelvin) * 3.0 / 2.0;
    if (unit == 5.0) return (kelvin - 273.15) * 33.0 / 100.0;
    if (unit == 6.0) return (kelvin - 273.15) * 4.0 / 5.0;
    return (kelvin - 273.15) * 21.0 / 40.0 + 7.5;
}

/// Convert a bounded value between the eight temperature scales.
export fn temperature(value: f64, from_unit: f64, to_unit: f64) f64 {
    if (std.math.isNan(value) or value < -1_000_000.0 or value > 1_000_000.0 or
        !validUnit(from_unit) or !validUnit(to_unit)) return -1e300;
    return fromKelvin(toKelvin(value, from_unit), to_unit);
}
