const std = @import("std");

const side: usize = 4;
const cells: usize = 64;

fn wrapIndex(value: isize, n: usize) usize {
    if (value < 0) return @intCast(value + @as(isize, @intCast(n)));
    if (value >= @as(isize, @intCast(n))) return @intCast(value - @as(isize, @intCast(n)));
    return @intCast(value);
}
fn gridIndex(x: usize, y: usize, z: usize, n: usize) usize { return x + n * (y + n * z); }
fn stencil(src: []const f64, dst: []f64, n: usize, center: f64, face: f64, edge: f64, corner: f64) void {
    for (0..n) |z| for (0..n) |y| for (0..n) |x| {
        const q = gridIndex(x, y, z, n);
        var total = center * src[q];
        for (0..3) |zi| for (0..3) |yi| for (0..3) |xi| {
            const dz: isize = @as(isize, @intCast(zi)) - 1;
            const dy: isize = @as(isize, @intCast(yi)) - 1;
            const dx: isize = @as(isize, @intCast(xi)) - 1;
            const distance = @abs(dx) + @abs(dy) + @abs(dz);
            if (distance == 0) continue;
            const weight = if (distance == 1) face else if (distance == 2) edge else corner;
            const neighbor = gridIndex(wrapIndex(@as(isize, @intCast(x)) + dx, n),
                wrapIndex(@as(isize, @intCast(y)) + dy, n), wrapIndex(@as(isize, @intCast(z)) + dz, n), n);
            total += weight * src[neighbor];
        };
        dst[q] = total;
    };
}
fn restrictGrid(fine: []const f64, n: usize, coarse: []f64) void {
    const h = n / 2;
    for (0..h) |z| for (0..h) |y| for (0..h) |x| {
        var total: f64 = 0;
        for (0..3) |zi| for (0..3) |yi| for (0..3) |xi| {
            const dz: isize = @as(isize, @intCast(zi)) - 1;
            const dy: isize = @as(isize, @intCast(yi)) - 1;
            const dx: isize = @as(isize, @intCast(xi)) - 1;
            const wx: f64 = if (dx == 0) 1.0 else 0.5;
            const wy: f64 = if (dy == 0) 1.0 else 0.5;
            const wz: f64 = if (dz == 0) 1.0 else 0.5;
            const q = gridIndex(wrapIndex(2 * @as(isize, @intCast(x)) + dx, n),
                wrapIndex(2 * @as(isize, @intCast(y)) + dy, n), wrapIndex(2 * @as(isize, @intCast(z)) + dz, n), n);
            total += wx * wy * wz * fine[q];
        };
        coarse[gridIndex(x, y, z, h)] = 0.5 * total;
    };
}
fn interpolateGrid(coarse: []const f64, h: usize, fine: []f64) void {
    const n = 2 * h;
    for (0..n) |z| for (0..n) |y| for (0..n) |x| {
        const bx = x / 2; const by = y / 2; const bz = z / 2;
        const nx: usize = if (x % 2 == 1) 2 else 1;
        const ny: usize = if (y % 2 == 1) 2 else 1;
        const nz: usize = if (z % 2 == 1) 2 else 1;
        const wx: f64 = if (x % 2 == 1) 0.5 else 1.0;
        const wy: f64 = if (y % 2 == 1) 0.5 else 1.0;
        const wz: f64 = if (z % 2 == 1) 0.5 else 1.0;
        var total: f64 = 0;
        for (0..nz) |iz| for (0..ny) |iy| for (0..nx) |ix| {
            total += wx * wy * wz * coarse[gridIndex((bx + ix) % h, (by + iy) % h, (bz + iz) % h, h)];
        };
        fine[gridIndex(x, y, z, n)] = total;
    };
}
fn vcycle(rhs: []const f64, n: usize, solution: []f64) void {
    if (n == 2) {
        stencil(rhs, solution, n, -3.0 / 8.0, 1.0 / 32.0, -1.0 / 64.0, 0.0);
        return;
    }
    const h = n / 2;
    var coarse_rhs: [64]f64 = @splat(0.0);
    var coarse_solution: [64]f64 = @splat(0.0);
    var prolonged: [64]f64 = @splat(0.0);
    var applied: [64]f64 = @splat(0.0);
    var remaining: [64]f64 = @splat(0.0);
    var post: [64]f64 = @splat(0.0);
    restrictGrid(rhs, n, coarse_rhs[0 .. h*h*h]);
    vcycle(coarse_rhs[0 .. h*h*h], h, coarse_solution[0 .. h*h*h]);
    interpolateGrid(coarse_solution[0 .. h*h*h], h, prolonged[0 .. n*n*n]);
    stencil(prolonged[0 .. n*n*n], applied[0 .. n*n*n], n, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0);
    for (0..n*n*n) |q| remaining[q] = rhs[q] - applied[q];
    stencil(remaining[0 .. n*n*n], post[0 .. n*n*n], n, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0);
    for (0..n*n*n) |q| solution[q] = prolonged[q] + post[q];
}

export fn npb_mg_vcycle(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 34) return -1;
    const input = input_opt.?;
    const iterations_v = input[0]; const count_v = input[1];
    if (!std.math.isFinite(iterations_v) or @trunc(iterations_v) != iterations_v or iterations_v < 1 or iterations_v > 4 or
        !std.math.isFinite(count_v) or @trunc(count_v) != count_v or count_v < 0 or count_v > 8) return -1;
    const iterations: usize = @intFromFloat(iterations_v);
    const count: usize = @intFromFloat(count_v);
    if (length != 2 + 4 * count) return -1;
    var rhs: [cells]f64 = @splat(0.0);
    var seen: [cells]bool = @splat(false);
    for (0..count) |source| {
        const base = 2 + 4 * source;
        const xv = input[base]; const yv = input[base + 1]; const zv = input[base + 2]; const value = input[base + 3];
        if (!std.math.isFinite(xv) or @trunc(xv) != xv or xv < 0 or xv >= 4 or
            !std.math.isFinite(yv) or @trunc(yv) != yv or yv < 0 or yv >= 4 or
            !std.math.isFinite(zv) or @trunc(zv) != zv or zv < 0 or zv >= 4 or
            !std.math.isFinite(value) or value < -4 or value > 4) return -1;
        const q = gridIndex(@intFromFloat(xv), @intFromFloat(yv), @intFromFloat(zv), side);
        if (seen[q]) return -1;
        seen[q] = true;
        rhs[q] = value;
    }
    if (output_opt == null or capacity < 1) return -2;
    var solution: [cells]f64 = @splat(0.0);
    var applied: [cells]f64 = @splat(0.0);
    var residual: [cells]f64 = @splat(0.0);
    var correction: [cells]f64 = @splat(0.0);
    for (0..iterations) |_| {
        stencil(solution[0..], applied[0..], side, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0);
        for (0..cells) |q| residual[q] = rhs[q] - applied[q];
        vcycle(residual[0..], side, correction[0..]);
        for (0..cells) |q| solution[q] += correction[q];
    }
    var checksum: f64 = 0;
    for (solution) |value| checksum += value;
    const output = output_opt.?;
    output[0] = checksum;
    return 1;
}
