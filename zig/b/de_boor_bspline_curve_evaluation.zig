const std = @import("std");

const max_input_length: usize = 24;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

fn evaluate(p: usize, n: usize, u: f64, knots: []const f64, controls: []const f64) f64 {
    var span = p;
    if (u == knots[n]) {
        span = n - 1;
    } else {
        while (span < n - 1 and u >= knots[span + 1]) : (span += 1) {}
    }
    var local = [_]f64{0.0} ** 4;
    for (0..p + 1) |j| local[j] = controls[span - p + j];
    for (1..p + 1) |level| {
        var slot = p;
        while (slot >= level) : (slot -= 1) {
            const left = span - p + slot;
            const right = span + slot - level + 1;
            const denominator = knots[right] - knots[left];
            const alpha = if (denominator == 0.0) 0.0 else (u - knots[left]) / denominator;
            local[slot] = (1.0 - alpha) * local[slot - 1] + alpha * local[slot];
        }
    }
    return local[p];
}

export fn de_boor_bspline_curve_evaluation(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > max_input_length or
        !exactInteger(values[0], 1, 3) or !std.math.isFinite(values[2])) return -1;
    const p: usize = @intFromFloat(values[0]);
    if (!exactInteger(values[1], @floatFromInt(p + 1), 8)) return -1;
    const n: usize = @intFromFloat(values[1]);
    const knot_count = n + p + 1;
    if (input_length != 3 + knot_count + n) return -1;
    const knots = values[3 .. 3 + knot_count];
    const controls = values[3 + knot_count .. 3 + knot_count + n];
    var run: usize = 1;
    for (knots, 0..) |value, i| {
        if (!std.math.isFinite(value) or value < -1000.0 or value > 1000.0) return -1;
        if (i > 0) {
            if (value < knots[i - 1]) return -1;
            run = if (value == knots[i - 1]) run + 1 else 1;
            if (run > p + 1) return -1;
        }
    }
    for (controls) |value| {
        if (!std.math.isFinite(value) or value < -1000.0 or value > 1000.0) return -1;
    }
    const u = values[2];
    if (!(knots[p] < knots[n] and u >= knots[p] and u <= knots[n])) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    const result = evaluate(p, n, u, knots, controls);
    if (!std.math.isFinite(result)) return -1;
    out[0] = result;
    return 1;
}
