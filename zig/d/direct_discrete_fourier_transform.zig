const std = @import("std");

const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const TAU = 6.283185307179586476925286766559;

export fn direct_discrete_fourier_transform(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const n_value = values[0];
    if (n_value < 1.0 or n_value > @as(f64, @floatFromInt(MAX_N))
        or @floor(n_value) != n_value) return -1;
    const n: usize = @intFromFloat(n_value);
    if (input_length != 1 + 2 * n) return -1;
    for (0..2 * n) |i| if (values[i + 1] < -8.0 or values[i + 1] > 8.0) return -1;

    const needed = 2 * n;
    const result = output orelse return -2;
    if (output_capacity < needed) return -2;
    for (0..n) |k| {
        var real_sum: f64 = 0.0;
        var imag_sum: f64 = 0.0;
        for (0..n) |j| {
            const angle = -TAU * @as(f64, @floatFromInt(j))
                * @as(f64, @floatFromInt(k)) / @as(f64, @floatFromInt(n));
            const cosine = @cos(angle);
            const sine = @sin(angle);
            const sample_real = values[1 + 2 * j];
            const sample_imag = values[2 + 2 * j];
            real_sum += sample_real * cosine + sample_imag * sine;
            imag_sum += sample_imag * cosine - sample_real * sine;
        }
        result[2 * k] = real_sum;
        result[2 * k + 1] = imag_sum;
    }
    return @intCast(needed);
}

