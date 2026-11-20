const std = @import("std");

const max_parseable_input_length: usize = 3;
const pi_pinned: f64 = 3.14159265358979323846264338327950288;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

fn integrate(function_id: i64, p: i64) f64 {
    const scale: i64 = @as(i64, 1) << @as(u6, @intCast(p));
    const h = 1.0 / @as(f64, @floatFromInt(scale));
    const half_pi = pi_pinned / 2.0;
    const limit: i64 = 3 * scale;
    var total: f64 = 0.0;
    var j: i64 = -limit;
    while (j <= limit) : (j += 1) {
        const t = @as(f64, @floatFromInt(j)) * h;
        const exp_t = @exp(t);
        const exp_minus_t = @exp(-t);
        const sinh_t = (exp_t-exp_minus_t)*0.5;
        const cosh_t = (exp_t+exp_minus_t)*0.5;
        const u = half_pi*sinh_t;
        const abs_u = if (u < 0.0) -u else u;
        const q = @exp(-2.0*abs_u);
        const one_plus_q = 1.0+q;
        const sech_squared = (4.0*q)/(one_plus_q*one_plus_q);
        const magnitude_x = (1.0-q)/one_plus_q;
        const x = if (u >= 0.0) magnitude_x else -magnitude_x;
        const jacobian = (half_pi*cosh_t)*sech_squared;
        const sample = if (function_id == 0) 1.0 else if (function_id == 1) x*x else if (function_id == 2)
            1.0/@sqrt(sech_squared) else if (u >= 0.0) 1.0/@sqrt((2.0*q)/one_plus_q) else 1.0/@sqrt(2.0/one_plus_q);
        const transformed = sample*jacobian;
        total += h*transformed;
    }
    return total;
}

export fn tanh_sinh_double_exponential_quadrature(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > max_parseable_input_length) return -1;
    if (input_length != 2 or !exactInteger(values[0],0.0,3.0) or !exactInteger(values[1],2.0,4.0)) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    const function_id: i64 = @intFromFloat(values[0]);
    const p: i64 = @intFromFloat(values[1]);
    const value = integrate(function_id,p);
    if (!std.math.isFinite(value)) return -1;
    out[0] = value;
    return 1;
}
