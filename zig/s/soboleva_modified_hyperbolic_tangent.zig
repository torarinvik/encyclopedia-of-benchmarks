const std = @import("std");

const MAX_SAMPLE_COUNT: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;

export fn soboleva_modified_hyperbolic_tangent(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 5 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const count_value = input[0];
    if (!std.math.isFinite(count_value) or count_value < 1.0 or count_value > @as(f64, @floatFromInt(MAX_SAMPLE_COUNT))) return -1;
    const count: usize = @intFromFloat(count_value);
    if (count_value != @as(f64, @floatFromInt(count)) or input_length != 5 + count) return -1;

    const a = input[1];
    const b = input[2];
    const c = input[3];
    const d = input[4];
    for ([_]f64{ a, b, c, d }) |coefficient| {
        if (!std.math.isFinite(coefficient) or coefficient < -2.0 or coefficient > 2.0) return -1;
    }
    for (0..count) |index| {
        const x = input[index + 5];
        if (!std.math.isFinite(x) or x < -20.0 or x > 20.0) return -1;
    }
    if (output == null or output_capacity < count) return -2;

    for (0..count) |index| {
        const x = input[index + 5];
        const exp_ax = @exp(a * x);
        const exp_neg_bx = @exp((-b) * x);
        const numerator = exp_ax - exp_neg_bx;
        const exp_cx = @exp(c * x);
        const exp_neg_dx = @exp((-d) * x);
        const denominator = exp_cx + exp_neg_dx;
        output[index] = numerator / denominator;
    }
    return @intCast(count);
}
