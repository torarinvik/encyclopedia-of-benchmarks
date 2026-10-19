const MAX_N = 40;

export fn durbin(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (!std.math.isFinite(n_value) or @trunc(n_value) != n_value or n_value < 1.0 or n_value > MAX_N) return -1;
    const n: usize = @intFromFloat(n_value);
    if (output_opt == null or capacity < n) return -2;

    var r: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    var y: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    var z: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    for (0..n) |i| r[i] = @floatFromInt(n + 1 - i);
    y[0] = -r[0];
    var beta: f64 = 1.0;
    var alpha: f64 = -r[0];
    for (1..n) |k| {
        beta = (1.0 - alpha * alpha) * beta;
        var sum: f64 = 0.0;
        for (0..k) |i| sum += r[k - i - 1] * y[i];
        alpha = -(r[k] + sum) / beta;
        for (0..k) |i| z[i] = y[i] + alpha * y[k - i - 1];
        for (0..k) |i| y[i] = z[i];
        y[k] = alpha;
    }
    const output = output_opt.?;
    for (0..n) |i| output[i] = y[i];
    return @intCast(n);
}

const std = @import("std");
