const std = @import("std");
const invalid_result: f64 = -1.0e300;
fn roundTwoPython(value: f64) f64 {
    if (value == 0.0) return value;
    const negative = value < 0.0;
    var normalized = if (negative) -value else value;
    var exponent: i32 = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent += 1; }
    while (normalized < 0.5) { normalized *= 2.0; exponent -= 1; }
    const significand: u64 = @intFromFloat(normalized * 9_007_199_254_740_992.0);
    const numerator = significand * 100;
    const shift = 53 - exponent;
    var cents: u64 = 0;
    if (shift < 0) cents = numerator << @intCast(-shift)
    else if (shift == 0) cents = numerator
    else if (shift < 64) {
        const denominator: u64 = @as(u64, 1) << @intCast(shift);
        cents = numerator >> @intCast(shift);
        const remainder = numerator & (denominator - 1);
        const half = denominator >> 1;
        if (remainder > half or (remainder == half and (cents & 1) != 0)) cents += 1;
    }
    const rounded = @as(f64, @floatFromInt(cents)) / 100.0;
    return if (negative) -rounded else rounded;
}
export fn present_value(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 3 or length > 10) return invalid_result;
    const count_value = values[0];
    const rate_ppm = values[1];
    if (count_value < 1 or count_value > 8 or length != 2 + @as(usize, @intCast(count_value)) or rate_ppm != 0 and rate_ppm != 1_000_000) return invalid_result;
    const count: usize = @intCast(count_value);
    for (0..count) |i| if (values[i + 2] < -1_000_000 or values[i + 2] > 1_000_000 || values[i + 2] % 125 != 0) return invalid_result;
    const rate = @as(f64, @floatFromInt(rate_ppm)) / 1_000_000.0;
    var total: f64 = 0.0;
    for (0..count) |i| {
        const flow = @as(f64, @floatFromInt(values[i + 2])) / 1000.0;
        total += flow / std.math.pow(f64, 1.0 + rate, @floatFromInt(i));
    }
    return roundTwoPython(total);
}
