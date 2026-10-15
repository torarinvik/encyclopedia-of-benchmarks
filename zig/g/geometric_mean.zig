const MAX_LENGTH: usize = 6;
const MAX_ABS_VALUE: i64 = 100;
const INVALID_RESULT: f64 = -1.0e300;

export fn geometric_mean(values: [*]const i64, length: usize) f64 {
    if (length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    var product: i64 = 1;
    for (0..length) |index| {
        const value = values[index];
        if (value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE) return INVALID_RESULT;
        product *= value;
    }
    if (product < 0 and length % 2 == 0) return INVALID_RESULT;
    var root = std.math.pow(f64, @as(f64, @floatFromInt(@abs(product))), 1.0 / @as(f64, @floatFromInt(length)));
    const rounded = @floor(root + 0.5);
    var rounded_power: i64 = 1;
    for (0..length) |_| {
        rounded_power *= @as(i64, @intFromFloat(rounded));
    }
    if ((product >= 0 and rounded_power == product)
        or (product < 0 and length % 2 == 1 and -rounded_power == product)) root = rounded;
    if (product < 0) root = -root;
    return root;
}

const std = @import("std");
