/// Binary negative log-likelihood with source-ordered accumulation.
const std = @import("std");

export fn negative_log_likelihood(values: [*]const i64, length: usize) f64 {
    if (length < 1) return -1.0e300;
    const count = values[0];
    if (count < 1 or count > 64 or length != 1 + 2 * @as(usize, @intCast(count))) return -1.0e300;
    var total: f64 = 0.0;
    for (0..@as(usize, @intCast(count))) |i| {
        const actual_scaled = values[1 + i];
        const predicted_scaled = values[1 + @as(usize, @intCast(count)) + i];
        if (actual_scaled < 0 or actual_scaled > 1_000_000 or predicted_scaled < 1 or predicted_scaled > 999_999) return -1.0e300;
        const actual = @as(f64, @floatFromInt(actual_scaled)) / 1_000_000.0;
        const predicted = @as(f64, @floatFromInt(predicted_scaled)) / 1_000_000.0;
        total += -actual * @log(predicted) - (1.0 - actual) * @log(1.0 - predicted);
    }
    return total / @as(f64, @floatFromInt(count));
}
