const MAX_N = 30;
const MAX_TSTEPS = 20;

export fn jacobi_2d(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const steps_value = input[1];
    if (!std.math.isFinite(n_value) or !std.math.isFinite(steps_value) or
        @trunc(n_value) != n_value or @trunc(steps_value) != steps_value or
        n_value < 1.0 or n_value > MAX_N or steps_value < 0.0 or steps_value > MAX_TSTEPS) return -1;
    const n: usize = @intFromFloat(n_value);
    const tsteps: usize = @intFromFloat(steps_value);
    const count = n * n;
    if (output_opt == null or capacity < count) return -2;

    var a: [MAX_N][MAX_N]f64 = @splat(@splat(0.0));
    var b: [MAX_N][MAX_N]f64 = @splat(@splat(0.0));
    for (0..n) |i| {
        for (0..n) |j| {
            a[i][j] = (@as(f64, @floatFromInt(i)) * @as(f64, @floatFromInt(j + 2)) + 2.0) / @as(f64, @floatFromInt(n));
            b[i][j] = (@as(f64, @floatFromInt(i)) * @as(f64, @floatFromInt(j + 3)) + 3.0) / @as(f64, @floatFromInt(n));
        }
    }
    for (0..tsteps) |_| {
        if (n > 2) {
            for (1..(n - 1)) |i| {
                for (1..(n - 1)) |j|
                    b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j]);
            }
            for (1..(n - 1)) |i| {
                for (1..(n - 1)) |j|
                    a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j]);
            }
        }
    }
    const output = output_opt.?;
    for (0..n) |i| {
        for (0..n) |j| output[i * n + j] = a[i][j];
    }
    return @intCast(count);
}

const std = @import("std");
