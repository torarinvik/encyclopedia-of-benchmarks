const INVALID_RESULT: f64 = -1.0e300;

/// Calculate the generalized combination for a real total and integer choose.
export fn ncr_combinations(total: f64, choose: f64) f64 {
    if (std.math.isNan(total) or std.math.isNan(choose) or total < 0.0 or total > 20.0 or
        choose < 0.0 or choose > 12.0 or choose != @trunc(choose)) return INVALID_RESULT;

    const count: i64 = @intFromFloat(choose);
    var numerator: f64 = 1.0;
    var index: i64 = 0;
    while (index < count) : (index += 1) {
        numerator *= total - @as(f64, @floatFromInt(index));
    }
    var denominator: f64 = 1.0;
    var factor: i64 = 2;
    while (factor <= count) : (factor += 1) {
        denominator *= @as(f64, @floatFromInt(factor));
    }
    return numerator / denominator;
}

const std = @import("std");
