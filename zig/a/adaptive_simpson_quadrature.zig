const std = @import("std");

const max_input_length: usize = 6;

fn exactInteger(x: f64, low: f64, high: f64) bool {
    return std.math.isFinite(x) and x >= low and x <= high and @trunc(x) == x;
}

fn sample(function_id: i64, x: f64) f64 {
    return switch (function_id) {
        0 => x * x * x * x,
        1 => @sin(x),
        else => 1.0 / (1.0 + x * x),
    };
}

fn simpson(a: f64, b: f64, fa: f64, fm: f64, fb: f64) f64 {
    return (b - a) * (fa + 4.0 * fm + fb) / 6.0;
}

fn refine(function_id: i64, a: f64, b: f64, fa: f64, fm: f64, fb: f64,
    whole: f64, tolerance: f64, depth: i64) f64 {
    const middle = (a + b) * 0.5;
    const left_middle = (a + middle) * 0.5;
    const right_middle = (middle + b) * 0.5;
    const flm = sample(function_id, left_middle);
    const frm = sample(function_id, right_middle);
    const left = simpson(a, middle, fa, flm, fm);
    const right = simpson(middle, b, fm, frm, fb);
    const delta = left + right - whole;
    if (depth == 0 or @abs(delta) <= 15.0 * tolerance)
        return left + right + delta / 15.0;
    return refine(function_id, a, middle, fa, flm, fm, left, tolerance * 0.5, depth - 1) +
        refine(function_id, middle, b, fm, frm, fb, right, tolerance * 0.5, depth - 1);
}

export fn adaptive_simpson_quadrature(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 5 or input_length > max_input_length or
        !exactInteger(values[0], 0, 2) or
        !exactInteger(values[1], -2_000_000, 2_000_000) or
        !exactInteger(values[2], -2_000_000, 2_000_000) or
        !exactInteger(values[3], 7, 8) or !exactInteger(values[4], 8, 12)) return -1;
    const function_id: i64 = @intFromFloat(values[0]);
    const a_micro: i64 = @intFromFloat(values[1]);
    const b_micro: i64 = @intFromFloat(values[2]);
    const exponent: i64 = @intFromFloat(values[3]);
    const depth: i64 = @intFromFloat(values[4]);
    if (a_micro > b_micro) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    const a = @as(f64, @floatFromInt(a_micro)) / 1_000_000.0;
    const b = @as(f64, @floatFromInt(b_micro)) / 1_000_000.0;
    var result: f64 = 0.0;
    if (a != b) {
        const middle = (a + b) * 0.5;
        var tolerance: f64 = 1.0;
        var index: i64 = 0;
        while (index < exponent) : (index += 1) tolerance *= 0.1;
        const fa = sample(function_id, a);
        const fm = sample(function_id, middle);
        const fb = sample(function_id, b);
        result = refine(function_id, a, b, fa, fm, fb,
            simpson(a, b, fa, fm, fb), tolerance, depth);
    }
    if (!std.math.isFinite(result)) return -1;
    out[0] = result;
    return 1;
}
