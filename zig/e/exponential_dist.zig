const std = @import("std");

const MAX_RATE_MICRO: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn exponential_dist(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const operation = values[0];
    const rate_micro = values[1];
    if (operation < 0 or operation > 2 or rate_micro <= 0 or rate_micro > MAX_RATE_MICRO)
        return INVALID_RESULT;
    const rate = @as(f64, @floatFromInt(rate_micro)) / 1_000_000.0;
    if (operation == 1) return 1.0 / std.math.pow(f64, rate, 2.0);
    return 1.0 / rate;
}
