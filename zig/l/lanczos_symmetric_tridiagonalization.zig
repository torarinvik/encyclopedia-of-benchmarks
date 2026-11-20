const std = @import("std");

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

export fn lanczos_symmetric_tridiagonalization(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > 19) return -1;
    for (0..input_length) |index| if (!std.math.isFinite(values[index])) return -1;
    if (!exactInteger(values[0], 1.0, 4.0) or !exactInteger(values[1], 1.0, 4.0)) return -1;
    const n: usize = @intFromFloat(values[0]);
    const k: usize = @intFromFloat(values[1]);
    if (k > n or input_length != 2 + n * n) return -1;
    for (0..n) |row| {
        for (0..n) |col| {
            if (!exactInteger(values[2 + row * n + col], -4.0, 4.0) or
                values[2 + row * n + col] != values[2 + col * n + row]) return -1;
        }
    }
    const required = 2 * k;
    const out = output orelse return -2;
    if (output_capacity < required) return -2;
    var previous = [_]f64{0.0} ** 4;
    var current = [_]f64{0.0} ** 4;
    var product = [_]f64{0.0} ** 4;
    var residual = [_]f64{0.0} ** 4;
    var next = [_]f64{0.0} ** 4;
    var diagonal = [_]f64{0.0} ** 4;
    var off_diagonal = [_]f64{0.0} ** 3;
    current[0] = 1.0;
    var previous_beta = 0.0;
    for (0..k) |step| {
        for (0..n) |row| {
            product[row] = 0.0;
            for (0..n) |col| product[row] += values[2 + row * n + col] * current[col];
        }
        var alpha = 0.0;
        for (0..n) |index| alpha += current[index] * product[index];
        if (!std.math.isFinite(alpha)) return -3;
        diagonal[step] = alpha;
        if (step + 1 == k) break;
        var norm_squared = 0.0;
        for (0..n) |index| {
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index];
            norm_squared += residual[index] * residual[index];
        }
        if (!std.math.isFinite(norm_squared) or norm_squared < 0.0) return -3;
        const beta = @sqrt(norm_squared);
        if (!std.math.isFinite(beta) or beta <= 9.094947017729282e-13) return -3;
        off_diagonal[step] = beta;
        for (0..n) |index| next[index] = residual[index] / beta;
        for (0..n) |index| previous[index] = current[index];
        for (0..n) |index| current[index] = next[index];
        previous_beta = beta;
    }
    out[0] = @floatFromInt(k);
    for (0..k) |index| out[1 + index] = diagonal[index];
    for (0..k - 1) |index| out[1 + k + index] = off_diagonal[index];
    return @intCast(required);
}
