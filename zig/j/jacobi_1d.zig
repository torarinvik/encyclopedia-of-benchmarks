const MAX_N = 30;
const MAX_TSTEPS = 20;

export fn jacobi_1d(input_opt: ?[*]const f64, length: usize,
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
    if (output_opt == null or capacity < n) return -2;

    var a: [MAX_N]f64 = @splat(0.0);
    var b: [MAX_N]f64 = @splat(0.0);
    for (0..n) |i| {
        a[i] = (@as(f64, @floatFromInt(i)) + 2.0) / @as(f64, @floatFromInt(n));
        b[i] = (@as(f64, @floatFromInt(i)) + 3.0) / @as(f64, @floatFromInt(n));
    }
    for (0..tsteps) |_| {
        if (n > 2) {
            for (1..n - 1) |i| b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1]);
            for (1..n - 1) |i| a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1]);
        }
    }
    const output = output_opt.?;
    for (0..n) |i| output[i] = a[i];
    return @intCast(n);
}

const std = @import("std");
