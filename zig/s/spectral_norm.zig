const std = @import("std");

const MAX_DIMENSION: usize = 64;
const INVALID_RESULT: f64 = -1e300;

fn matrixEntry(i: usize, j: usize) f64 {
    const triangular = (i + j) * (i + j + 1) / 2;
    return 1.0 / @as(f64, @floatFromInt(triangular + i + 1));
}

fn multiplyA(n: usize, input: *const [MAX_DIMENSION]f64,
    output: *[MAX_DIMENSION]f64) void {
    for (0..n) |i| {
        var total: f64 = 0;
        for (0..n) |j| total += matrixEntry(i, j) * input[j];
        output[i] = total;
    }
}

fn multiplyAt(n: usize, input: *const [MAX_DIMENSION]f64,
    output: *[MAX_DIMENSION]f64) void {
    for (0..n) |i| {
        var total: f64 = 0;
        for (0..n) |j| total += matrixEntry(j, i) * input[j];
        output[i] = total;
    }
}

fn multiplyAta(n: usize, input: *const [MAX_DIMENSION]f64,
    output: *[MAX_DIMENSION]f64, temporary: *[MAX_DIMENSION]f64) void {
    multiplyA(n, input, temporary);
    multiplyAt(n, temporary, output);
}

export fn spectral_norm(values: ?[*]const i64, length: usize) f64 {
    const input = values orelse return INVALID_RESULT;
    if (length != 1 or input[0] < 1 or input[0] > MAX_DIMENSION) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    var u = [_]f64{0} ** MAX_DIMENSION;
    var v = [_]f64{0} ** MAX_DIMENSION;
    var temporary = [_]f64{0} ** MAX_DIMENSION;
    for (0..n) |i| u[i] = 1.0;
    for (0..10) |_| {
        multiplyAta(n, &u, &v, &temporary);
        multiplyAta(n, &v, &u, &temporary);
    }
    var v_b_v: f64 = 0;
    var v_v: f64 = 0;
    for (0..n) |i| {
        v_b_v += u[i] * v[i];
        v_v += v[i] * v[i];
    }
    return @sqrt(v_b_v / v_v);
}
