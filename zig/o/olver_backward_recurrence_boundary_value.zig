const std = @import("std");

const max_parseable_input_length: usize = 53;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

export fn olver_backward_recurrence_boundary_value(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 8 or input_length > max_parseable_input_length) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    if (!exactInteger(values[0], 1.0, 8.0) or !exactInteger(values[1], 1.0, 12.0)) return -1;
    const m: usize = @intFromFloat(values[0]);
    const nmax: usize = @intFromFloat(values[1]);
    if (m > nmax or input_length != 4 + 4 * nmax or values[2] < 0x1p-40 or values[2] > 0.5 or @abs(values[3]) > 16.0) return -1;
    for (0..nmax) |i| {
        if (@abs(values[4 + i]) < 0.0625 or @abs(values[4 + i]) > 16.0 or
            @abs(values[4 + nmax + i]) > 16.0 or @abs(values[4 + 2 * nmax + i]) > 16.0 or
            @abs(values[4 + 3 * nmax + i]) > 16.0) return -1;
    }
    const required = m + 2;
    const out = output orelse return -2;
    if (output_capacity < required) return -2;
    var p = [_]f64{0.0} ** 14;
    var e = [_]f64{0.0} ** 13;
    var w = [_]f64{0.0} ** 13;
    p[1] = 1.0;
    e[0] = values[3];
    for (1..m + 1) |n| {
        const a = values[4 + n - 1];
        const b = values[4 + nmax + n - 1];
        const c = values[4 + 2 * nmax + n - 1];
        const d = values[4 + 3 * nmax + n - 1];
        p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
        e[n] = (c * e[n - 1] - d * p[n]) / a;
        if (!std.math.isFinite(p[n + 1]) or !std.math.isFinite(e[n])) return -3;
    }
    for (1..m + 1) |n| {
        const product = p[n] * p[n + 1];
        if (product == 0.0 or !std.math.isFinite(product) or !std.math.isFinite(e[n] / product)) return -3;
    }
    var minimum = @abs(e[1] / (p[1] * p[2]));
    for (2..m + 1) |n| minimum = @min(minimum, @abs(e[n] / (p[n] * p[n + 1])));
    const threshold = values[2] * minimum;
    var endpoint: usize = 0;
    for (m..nmax + 1) |n| {
        if (n > m) {
            const a = values[4 + n - 1];
            const b = values[4 + nmax + n - 1];
            const c = values[4 + 2 * nmax + n - 1];
            const d = values[4 + 3 * nmax + n - 1];
            p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
            e[n] = (c * e[n - 1] - d * p[n]) / a;
            if (!std.math.isFinite(p[n + 1]) or !std.math.isFinite(e[n])) return -3;
        }
        const product = p[n] * p[n + 1];
        if (product == 0.0 or !std.math.isFinite(product)) return -3;
        const ratio = @abs(e[n] / product);
        if (!std.math.isFinite(ratio)) return -3;
        if (ratio <= threshold) { endpoint = n; break; }
    }
    if (endpoint == 0) return -3;
    var n = endpoint;
    while (n > 0) {
        n -= 1;
        w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1];
        if (!std.math.isFinite(w[n])) return -3;
    }
    out[0] = @floatFromInt(endpoint);
    for (0..m + 1) |i| out[i + 1] = w[i];
    return @intCast(required);
}
