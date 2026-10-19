const std = @import("std");

const MAX_N: usize = 8;
const MAX_M: usize = 16;

export fn syrk(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (!std.math.isFinite(n_value) or !std.math.isFinite(m_value)
        or @trunc(n_value) != n_value or @trunc(m_value) != m_value
        or n_value < 1.0 or n_value > @as(f64, @floatFromInt(MAX_N))
        or m_value < 1.0 or m_value > @as(f64, @floatFromInt(MAX_M))) return -1;
    const n: usize = @intFromFloat(n_value);
    const m: usize = @intFromFloat(m_value);
    const alpha: f64 = 1.5;
    const beta: f64 = 1.2;
    var a: [MAX_N * MAX_M]f64 = @splat(0.0);
    var c: [MAX_N * MAX_N]f64 = @splat(0.0);

    for (0..n) |i| {
        for (0..m) |k| {
            a[i * m + k] = @as(f64, @floatFromInt((i * k + 1) % n)) / @as(f64, @floatFromInt(n));
        }
    }
    for (0..n) |i| {
        for (0..n) |j| {
            c[i * n + j] = @as(f64, @floatFromInt((i * j + 2) % m)) / @as(f64, @floatFromInt(m));
        }
    }

    for (0..n) |i| {
        for (0..(i + 1)) |j| c[i * n + j] *= beta;
        for (0..m) |k| {
            for (0..(i + 1)) |j| {
                c[i * n + j] += alpha * a[i * m + k] * a[j * m + k];
            }
        }
    }

    const required = n * n;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..required) |index| output[index] = c[index];
    return @intCast(required);
}
