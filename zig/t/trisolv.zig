const MAX_N = 40;

export fn trisolv(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (!std.math.isFinite(n_value) or @trunc(n_value) != n_value or n_value < 1.0 or n_value > MAX_N) return -1;
    const n: usize = @intFromFloat(n_value);
    if (output_opt == null or capacity < n) return -2;

    var lower: [MAX_N][MAX_N]f64 = [_][MAX_N]f64{[_]f64{0.0} ** MAX_N} ** MAX_N;
    var b: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    var x: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    for (0..n) |i| {
        b[i] = @floatFromInt(i);
        for (0..i + 1) |j| {
            lower[i][j] = @as(f64, @floatFromInt(i + n - j + 1)) * 2.0 / @as(f64, @floatFromInt(n));
        }
    }
    for (0..n) |i| {
        x[i] = b[i];
        for (0..i) |j| x[i] -= lower[i][j] * x[j];
        x[i] /= lower[i][i];
    }
    const output = output_opt.?;
    for (0..n) |i| output[i] = x[i];
    return @intCast(n);
}

const std = @import("std");
