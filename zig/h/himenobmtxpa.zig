const std = @import("std");

export fn himenobmtxpa(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 4) return -1;
    const input = input_opt.?;
    var dims: [4]usize = undefined;
    for (0..4) |q| {
        const value = input[q];
        if (!std.math.isFinite(value) or @trunc(value) != value) return -1;
        if (q < 3) {
            if (value < 2 or value > 6) return -1;
        } else if (value < 1 or value > 4) return -1;
        dims[q] = @intFromFloat(value);
    }
    const nx = dims[0];
    const ny = dims[1];
    const nz = dims[2];
    const iterations = dims[3];
    if (output_opt == null or capacity < 1) return -2;

    var p: [216]f32 = @splat(0.0);
    var work: [216]f32 = @splat(0.0);
    const a3: f32 = 1.0 / 6.0;
    const omega: f32 = 0.8;
    const denominator: f32 = @floatFromInt((nx - 1) * (nx - 1));
    for (0..nx) |i| for (0..ny) |j| for (0..nz) |k| {
        const q = i * ny * nz + j * nz + k;
        p[q] = @as(f32, @floatFromInt(i * i)) / denominator;
    };
    var gosa: f32 = 0.0;
    for (0..iterations) |_| {
        gosa = 0.0;
        for (1..nx - 1) |i| for (1..ny - 1) |j| for (1..nz - 1) |k| {
            const q = i * ny * nz + j * nz + k;
            var s0 = p[q + ny * nz] + p[q + nz] + p[q + 1];
            s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1];
            const ss = s0 * a3 - p[q];
            gosa = gosa + ss * ss;
            work[q] = p[q] + omega * ss;
        };
        for (1..nx - 1) |i| for (1..ny - 1) |j| for (1..nz - 1) |k| {
            const q = i * ny * nz + j * nz + k;
            p[q] = work[q];
        };
    }
    const output = output_opt.?;
    output[0] = @as(f64, gosa);
    return 1;
}
