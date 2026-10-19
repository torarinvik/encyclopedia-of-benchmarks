// PolyBench/C trmm kernel, bounded port. Ohio State Software Distribution License: see benchmarks/t/trmm/LICENSE.txt.

const std = @import("std");
const MAX_M: usize = 8;
const MAX_N: usize = 8;

export fn trmm(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    const m_value = input[0]; const n_value = input[1];
    if (!std.math.isFinite(m_value) or !std.math.isFinite(n_value) or
        @trunc(m_value) != m_value or @trunc(n_value) != n_value or
        m_value < 1.0 or m_value > @as(f64, @floatFromInt(MAX_M)) or
        n_value < 1.0 or n_value > @as(f64, @floatFromInt(MAX_N))) return -1;
    const m: usize = @intFromFloat(m_value); const n: usize = @intFromFloat(n_value);
    const required = m*n;
    if (output_opt == null or capacity < required) return -2;
    var a: [MAX_M*MAX_M]f64 = @splat(0.0);
    var b: [MAX_M*MAX_N]f64 = @splat(0.0);
    for (0..m) |i| {
        for (0..i) |j| a[i*m+j] = @as(f64, @floatFromInt((i+j)%m)) / @as(f64, @floatFromInt(m));
        a[i*m+i] = 1.0;
        for (0..n) |j| b[i*n+j] = @as(f64, @floatFromInt((n+i-j)%n)) / @as(f64, @floatFromInt(n));
    }
    for (0..m) |i| for (0..n) |j| {
        for (i+1..m) |k| b[i*n+j] += a[k*m+i] * b[k*n+j];
        b[i*n+j] *= 1.5;
    };
    var staged: [MAX_M*MAX_N]f64 = @splat(0.0);
    for (0..required) |i| staged[i] = b[i];
    const output = output_opt.?;
    for (0..required) |i| output[i] = staged[i];
    return @intCast(required);
}
