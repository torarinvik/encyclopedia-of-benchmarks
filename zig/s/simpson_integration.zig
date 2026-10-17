const INVALID_RESULT: f64 = -1.0e300;
const MAX_ENDPOINT_MICRO: i64 = 10_000_000;
const std = @import("std");

fn integrand(x: f64) f64 {
    return @exp(-x) * (4.0 - std.math.pow(f64, x, 2.0));
}

export fn simpson_integration(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3) return INVALID_RESULT;
    const intervals = values[0];
    const a_micro = values[1];
    const b_micro = values[2];
    if (intervals < 2 or intervals > 128 or @rem(intervals, 2) != 0 or
        a_micro < -MAX_ENDPOINT_MICRO or a_micro > MAX_ENDPOINT_MICRO or
        b_micro < -MAX_ENDPOINT_MICRO or b_micro > MAX_ENDPOINT_MICRO or a_micro > b_micro) {
        return INVALID_RESULT;
    }
    const a = @as(f64, @floatFromInt(a_micro)) / 1_000_000.0;
    const b = @as(f64, @floatFromInt(b_micro)) / 1_000_000.0;
    if (a == b) return 0.0;
    const h = (b - a) / @as(f64, @floatFromInt(intervals));
    var xi = a;
    var total: f64 = 0.0;
    for (0..@intCast(intervals + 1)) |index| {
        const sample = integrand(xi);
        if (index == 0 or index == @as(usize, @intCast(intervals))) total += sample
        else if (index % 2 != 0) total += 4.0 * sample
        else total += 2.0 * sample;
        xi += h;
    }
    return (h / 3.0) * total;
}
