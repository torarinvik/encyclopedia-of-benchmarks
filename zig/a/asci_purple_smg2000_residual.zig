// Clean-room bounded residual profile; see package README and RIGHTS.md.
const std = @import("std");

export fn asci_purple_smg2000_residual(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 19 or length > 253) return -1;
    const input = input_opt.?;
    for (0..3) |q| {
        const v = input[q];
        if (!std.math.isFinite(v) or @trunc(v) != v or v < 2 or v > 5) return -1;
    }
    const nx: usize = @intFromFloat(input[0]);
    const ny: usize = @intFromFloat(input[1]);
    const nz: usize = @intFromFloat(input[2]);
    const cells = nx * ny * nz;
    if (length != 3 + 2 * cells) return -1;
    for (3..length) |q| {
        const v = input[q];
        if (!std.math.isFinite(v) or @trunc(v) != v or v < -1000 or v > 1000) return -1;
    }
    if (output_opt == null or capacity < cells) return -2;
    const output = output_opt.?;
    const si = ny * nz;
    const sj = nz;
    for (0..nx) |i| for (0..ny) |j| for (0..nz) |k| {
        const q = i * si + j * sj + k;
        const x: i64 = @intFromFloat(input[3 + q]);
        var ax: i64 = 222 * x;
        if (i > 0) ax -= @as(i64, @intFromFloat(input[3 + q - si]));
        if (i + 1 < nx) ax -= @as(i64, @intFromFloat(input[3 + q + si]));
        if (j > 0) ax -= 10 * @as(i64, @intFromFloat(input[3 + q - sj]));
        if (j + 1 < ny) ax -= 10 * @as(i64, @intFromFloat(input[3 + q + sj]));
        if (k > 0) ax -= 100 * @as(i64, @intFromFloat(input[3 + q - 1]));
        if (k + 1 < nz) ax -= 100 * @as(i64, @intFromFloat(input[3 + q + 1]));
        const b: i64 = @intFromFloat(input[3 + cells + q]);
        output[q] = @as(f64, @floatFromInt(10 * b - ax)) / 10.0;
    };
    return @intCast(cells);
}
