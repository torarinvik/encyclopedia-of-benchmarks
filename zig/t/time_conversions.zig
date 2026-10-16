const std = @import("std");

fn secondsFactor(code: f64) f64 {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 60.0;
    if (code == 2.0) return 3600.0;
    if (code == 3.0) return 86400.0;
    if (code == 4.0) return 604800.0;
    if (code == 5.0) return 2629800.0;
    if (code == 6.0) return 31557600.0;
    return 0.0;
}

fn inverseFactor(code: f64) f64 {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 0.016666666666666666;
    if (code == 2.0) return 0.0002777777777777778;
    if (code == 3.0) return 0.000011574074074074073;
    if (code == 4.0) return 0.0000016534391534391535;
    if (code == 5.0) return 0.0000003802570537683474;
    if (code == 6.0) return 0.00000003168808781402895;
    return 0.0;
}

fn roundThreeTiesEven(value: f64) f64 {
    const scaled = value * 1000.0;
    const lower = @floor(scaled);
    const fraction = scaled - lower;
    const residual = @mulAdd(f64, value, 1000.0, -scaled);
    var rounded = lower;
    if (fraction > 0.5 or (fraction == 0.5 and (residual > 0.0 or (residual == 0.0 and @mod(@as(i64, @intFromFloat(lower)), 2) != 0)))) {
        rounded = lower + 1.0;
    }
    return rounded / 1000.0;
}

/// Convert time using the source tables and round to three places.
export fn time_conversions(time_value: f64, from_code: f64, to_code: f64) f64 {
    if (std.math.isNan(time_value) or time_value < 0.0 or time_value > 10_000.0) return -1e300;
    const source = secondsFactor(from_code);
    const inverse = inverseFactor(to_code);
    if (source == 0.0 or inverse == 0.0) return -1e300;
    const scaled = time_value * source;
    return roundThreeTiesEven(scaled * inverse);
}
