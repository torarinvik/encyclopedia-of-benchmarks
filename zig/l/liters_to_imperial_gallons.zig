const std = @import("std");

export fn liters_to_imperial_gallons(liters: f64) f64 {
    if (!std.math.isFinite(liters) or liters < -1e100 or liters > 1e100) return -1e300;
    return liters / 4.54609;
}
