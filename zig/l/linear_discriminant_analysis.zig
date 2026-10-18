const std = @import("std");
const max_classes = 4;
const max_samples = 16;
const max_input = 22;
const min_margin = 1e-8;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and value >= minimum and value <= maximum and @trunc(value) == value;
}

export fn linear_discriminant_analysis(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length == 0 or input_length > max_input) return -1;
    if (!exactInteger(values[0], 2, 4)) return -1;
    const class_count: usize = @intFromFloat(values[0]);
    if (input_length < 1 + class_count) return -1;
    var counts = [_]usize{0} ** max_classes;
    var total_count: usize = 0;
    for (0..class_count) |k| {
        if (!exactInteger(values[1 + k], 2, 6)) return -1;
        counts[k] = @intFromFloat(values[1 + k]);
        total_count += counts[k];
    }
    if (total_count > max_samples or input_length != 1 + class_count + total_count) return -1;
    var groups = [_]f64{0} ** (max_classes * 6);
    var means = [_]f64{0} ** max_classes;
    var offset: usize = 1 + class_count;
    for (0..class_count) |k| {
        var sum: f64 = 0;
        for (0..counts[k]) |j| {
            const x = values[offset];
            offset += 1;
            if (!exactInteger(x, -32, 32)) return -1;
            groups[k * 6 + j] = x;
            sum += x;
        }
        means[k] = sum / @as(f64, @floatFromInt(counts[k]));
        if (!exactInteger(means[k], -32, 32)) return -1;
    }
    var squared_sum: f64 = 0;
    for (0..class_count) |k| {
        for (0..counts[k]) |j| {
            const delta = groups[k * 6 + j] - means[k];
            squared_sum += delta * delta;
        }
    }
    const variance = (1.0 / @as(f64, @floatFromInt(total_count - class_count))) * squared_sum;
    if (!std.math.isFinite(variance) or variance <= 0) return -1;
    var priors = [_]f64{0} ** max_classes;
    for (0..class_count) |k| priors[k] = @as(f64, @floatFromInt(counts[k])) / @as(f64, @floatFromInt(total_count));
    var staged = [_]f64{0} ** max_samples;
    var n: usize = 0;
    for (0..class_count) |group| {
        for (0..counts[group]) |j| {
            const x = groups[group * 6 + j];
            var best: f64 = -1e300;
            var second: f64 = -1e300;
            var winner: usize = 0;
            for (0..class_count) |k| {
                const score = x * (means[k] / variance) - (means[k] * means[k] / (2.0 * variance)) + @log(priors[k]);
                if (score > best) { second = best; best = score; winner = k; }
                else if (score > second) { second = score; }
            }
            if (!std.math.isFinite(best) or best - second < min_margin) return -1;
            staged[n] = @floatFromInt(winner);
            n += 1;
        }
    }
    const out = output orelse return -2;
    if (capacity < n) return -2;
    @memcpy(out[0..n], staged[0..n]);
    return @intCast(n);
}
