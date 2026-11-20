const std = @import("std");

const max_parseable_input_length: usize = 19;
const pi_pinned: f64 = 3.14159265358979323846264338327950288;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

fn compute(n: i64, samples: [*]const f64) f64 {
    var result: f64 = 0.0;
    var k: i64 = 0;
    while (k <= n) : (k += 1) {
        var inner: f64 = 0.0;
        var j: i64 = 1;
        while (j <= @divTrunc(n, 2)) : (j += 1) {
            const bj: f64 = if (j == @divTrunc(n, 2)) 1.0 else 2.0;
            const denominator = @as(f64, @floatFromInt(4 * j * j - 1));
            const angle = (((2.0 * @as(f64, @floatFromInt(j))) * @as(f64, @floatFromInt(k))) * pi_pinned) /
                @as(f64, @floatFromInt(n));
            const term = (bj / denominator) * @cos(angle);
            inner += term;
        }
        const gk: f64 = if (k == 0 or k == n) 1.0 else 2.0;
        const weight = (gk / @as(f64, @floatFromInt(n))) * (1.0 - inner);
        result += weight * samples[@intCast(k)];
    }
    return result;
}

export fn clenshaw_curtis_quadrature(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 4 or input_length > max_parseable_input_length) return -1;
    if (!exactInteger(values[0], 2, 16)) return -1;
    const n: i64 = @intFromFloat(values[0]);
    if (@mod(n, 2) != 0 or input_length != @as(usize, @intCast(n + 2))) return -1;
    for (1..input_length) |i| {
        if (!std.math.isFinite(values[i]) or @abs(values[i]) > 1000.0) return -1;
    }
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    const result = compute(n, values + 1);
    if (!std.math.isFinite(result)) return -1;
    out[0] = result;
    return 1;
}
