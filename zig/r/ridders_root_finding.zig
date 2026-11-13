const std = @import("std");

const max_input_length: usize = 6;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

fn polynomial(id: i64, x: f64) f64 {
    return switch (id) {
        0 => x*x-2.0,
        1 => x*x*x-2.0,
        2 => x*x*x+x-1.0,
        else => x,
    };
}

fn opposite(a: f64, b: f64) bool { return (a < 0.0) != (b < 0.0); }

export fn ridders_root_finding(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 5 or input_length > max_input_length or
        !exactInteger(values[0], 0, 3) or !exactInteger(values[1], -3000, 3000) or
        !exactInteger(values[2], -3000, 3000) or !exactInteger(values[3], 1, 1000) or
        !exactInteger(values[4], 24, 32)) return -1;
    const id: i64 = @intFromFloat(values[0]);
    const left_milli: i64 = @intFromFloat(values[1]);
    const right_milli: i64 = @intFromFloat(values[2]);
    const tolerance_micro: i64 = @intFromFloat(values[3]);
    const iterations: i64 = @intFromFloat(values[4]);
    if (left_milli >= right_milli) return -1;
    var left = @as(f64, @floatFromInt(left_milli))/1000.0;
    var right = @as(f64, @floatFromInt(right_milli))/1000.0;
    var f_left = polynomial(id, left);
    var f_right = polynomial(id, right);
    if (f_left != 0.0 and f_right != 0.0 and !opposite(f_left, f_right)) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    if (f_left == 0.0) { out[0] = left; return 1; }
    if (f_right == 0.0) { out[0] = right; return 1; }
    const tolerance = @as(f64, @floatFromInt(tolerance_micro))/1_000_000.0;
    var step: i64 = 0;
    while (step < iterations) : (step += 1) {
        if (right-left <= tolerance) { out[0] = (left+right)*0.5; return 1; }
        const middle = (left+right)*0.5;
        const f_middle = polynomial(id, middle);
        if (f_middle == 0.0) { out[0] = middle; return 1; }
        const radicand = f_middle*f_middle-f_left*f_right;
        if (!std.math.isFinite(radicand) or radicand <= 0.0) return -3;
        const denominator = @sqrt(radicand);
        if (!std.math.isFinite(denominator) or denominator == 0.0) return -3;
        const direction: f64 = if (f_left < f_right) -1.0 else 1.0;
        const candidate = middle+(middle-left)*direction*f_middle/denominator;
        if (!std.math.isFinite(candidate) or candidate <= left or candidate >= right) return -3;
        const f_candidate = polynomial(id, candidate);
        if (f_candidate == 0.0) { out[0] = candidate; return 1; }
        if (opposite(f_left, f_candidate)) { right = candidate; f_right = f_candidate; }
        else { left = candidate; f_left = f_candidate; }
        if (right-left <= tolerance) { out[0] = (left+right)*0.5; return 1; }
    }
    return -3;
}
