/// Cross-entropy loss with source-ordered intermediate terms and summation.
const std = @import("std");

export fn cross_entropy_loss(values: [*]const i64, length: usize) f64 {
    if (length < 1) return -1.0e300;
    const count = values[0];
    if (count < 1 or count > 64 or length != 1 + 2 * @as(usize, @intCast(count))) return -1.0e300;
    var terms: [64]f64 = @splat(0.0);
    for (0..@as(usize, @intCast(count))) |i| {
        const actual_scaled = values[1 + i];
        const predicted_scaled = values[1 + @as(usize, @intCast(count)) + i];
        if (actual_scaled < 0 or actual_scaled > 1_000_000 or
            predicted_scaled < 1 or predicted_scaled > 1_000_000) return -1.0e300;
        const actual = @as(f64, @floatFromInt(actual_scaled)) / 1_000_000.0;
        const predicted = @as(f64, @floatFromInt(predicted_scaled)) / 1_000_000.0;
        terms[i] = -actual * @log(predicted);
    }
    var total: f64 = 0.0;
    for (0..@as(usize, @intCast(count))) |i| total += terms[i];
    return total;
}
