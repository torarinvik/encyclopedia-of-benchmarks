// Rodinia SRAD v2 bounded two-kernel profile; full source license and citations:
// benchmarks/r/rodinia_srad_v2/LICENSE.txt.
const std = @import("std");
const PIXELS: usize = 256;
const INPUTS: usize = 258;
const LAMBDA_MIN: u32 = 0x3c23d70a;
const LAMBDA_MAX: u32 = 0x3dcccccd;
const Q0_MIN: u32 = 0x3c23d70a;
const Q0_MAX: u32 = 0x3f800000;
const J_MIN: u32 = 0x3f800000;
const J_MAX: u32 = 0x3fa00000;

fn add32(a: f32, b: f32) f32 { return a + b; }
fn sub32(a: f32, b: f32) f32 { return a - b; }
fn mul32(a: f32, b: f32) f32 { return a * b; }
fn div32(a: f32, b: f32) f32 { return a / b; }

pub export fn rodinia_srad_v2(values: ?[*]const i64, length: usize) i64 {
    const v = values orelse return -1;
    if (length != INPUTS) return -1;
    for (0..length) |i| if (v[i] < 0 or v[i] > std.math.maxInt(u32)) return -1;
    const lambda_bits: u32 = @intCast(v[0]);
    const q0_bits: u32 = @intCast(v[1]);
    if (lambda_bits < LAMBDA_MIN or lambda_bits > LAMBDA_MAX or q0_bits < Q0_MIN or q0_bits > Q0_MAX) return -1;
    const lambda: f32 = @bitCast(lambda_bits);
    const q0sqr: f32 = @bitCast(q0_bits);
    var image = [_]f32{0} ** PIXELS;
    var coeff = [_]f32{0} ** PIXELS;
    var north = [_]f32{0} ** PIXELS;
    var south = [_]f32{0} ** PIXELS;
    var west = [_]f32{0} ** PIXELS;
    var east = [_]f32{0} ** PIXELS;
    for (0..PIXELS) |i| {
        const bits: u32 = @intCast(v[i + 2]);
        if (bits < J_MIN or bits > J_MAX) return -1;
        image[i] = @bitCast(bits);
    }

    for (0..16) |row| {
        for (0..16) |col| {
            const i = row * 16 + col;
            const jc = image[i];
            const n = sub32(image[(if (row > 0) row - 1 else row) * 16 + col], jc);
            const s = sub32(image[(if (row < 15) row + 1 else row) * 16 + col], jc);
            const w = sub32(image[row * 16 + (if (col > 0) col - 1 else col)], jc);
            const e = sub32(image[row * 16 + (if (col < 15) col + 1 else col)], jc);
            north[i] = n; south[i] = s; west[i] = w; east[i] = e;
            var gradient = add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e));
            gradient = div32(gradient,mul32(jc,jc));
            const laplacian = div32(add32(add32(add32(n,s),w),e),jc);
            const lap_sq = mul32(laplacian,laplacian);
            const num: f32 = @floatCast(0.5 * @as(f64, gradient) - (1.0 / 16.0) * @as(f64, lap_sq));
            var den: f32 = @floatCast(1.0 + 0.25 * @as(f64, laplacian));
            if (den == 0) return -1;
            const qsqr = div32(num,mul32(den,den));
            den = div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(1.0,q0sqr)));
            if (den == -1) return -1;
            const c: f32 = @floatCast(1.0 / (1.0 + @as(f64, den)));
            if (!std.math.isFinite(c)) return -1;
            coeff[i] = @min(1.0, @max(0.0, c));
        }
    }

    var checksum: i64 = 0;
    for (0..16) |row| {
        for (0..16) |col| {
            const i = row * 16 + col;
            const cc = coeff[i];
            const cs = coeff[(if (row < 15) row + 1 else row) * 16 + col];
            const ce = coeff[row * 16 + (if (col < 15) col + 1 else col)];
            const divergence = add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]));
            const updated: f32 = @floatCast(@as(f64, image[i]) + 0.25 * @as(f64, lambda) * @as(f64, divergence));
            if (!std.math.isFinite(updated) or updated < 0) return -1;
            checksum += @intFromFloat(@as(f64, updated) * 1_000_000.0 + 0.5);
        }
    }
    return checksum;
}
