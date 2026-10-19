const std = @import("std");
const MAX_WIDTH: usize = 32;
const MAX_HEIGHT: usize = 32;
const MAX_PIXELS: usize = MAX_WIDTH * MAX_HEIGHT;
const INVALID_RESULT: f64 = -1e300;

fn filterOnce(width: usize, height: usize, image: []const f32,
    output: []f32, y1: []f32, y2: []f32) void {
    const alpha: f32 = 0.25;
    const exp_neg_alpha: f32 = @exp(-alpha);
    const difference = 1.0 - exp_neg_alpha;
    const numerator = difference * difference;
    const denominator_left = 1.0 + 2.0 * alpha * exp_neg_alpha;
    const k = numerator / (denominator_left - @exp(2.0 * alpha));
    const a1 = k;
    const a2 = k * exp_neg_alpha * (alpha - 1.0);
    const a3 = k * exp_neg_alpha * (alpha + 1.0);
    const a4 = -k * @exp(-2.0 * alpha);
    const a5 = k; const a6 = a2; const a7 = a3; const a8 = a4;
    const b1 = std.math.pow(f32, 2.0, -alpha);
    const b2 = -@exp(-2.0 * alpha);
    for (0..width) |i| {
        var ym1: f32 = 0; var ym2: f32 = 0; var xm1: f32 = 0;
        for (0..height) |j| {
            const at = i * height + j;
            var value = a1 * image[at] + a2 * xm1;
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value;
            xm1 = image[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (0..width) |i| {
        var yp1: f32 = 0; var yp2: f32 = 0; var xp1: f32 = 0; var xp2: f32 = 0;
        var j = height;
        while (j > 0) {
            j -= 1; const at = i * height + j;
            var value = a3 * xp1 + a4 * xp2;
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value;
            xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (0..width) |i| for (0..height) |j| {
        const at = i * height + j; output[at] = 1.0 * (y1[at] + y2[at]);
    };
    for (0..height) |j| {
        var tm1: f32 = 0; var ym1: f32 = 0; var ym2: f32 = 0;
        for (0..width) |i| {
            const at = i * height + j;
            var value = a5 * output[at] + a6 * tm1;
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value;
            tm1 = output[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (0..height) |j| {
        var tp1: f32 = 0; var tp2: f32 = 0; var yp1: f32 = 0; var yp2: f32 = 0;
        var i = width;
        while (i > 0) {
            i -= 1; const at = i * height + j;
            var value = a7 * tp1 + a8 * tp2;
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value;
            tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (0..width * height) |at| output[at] = 1.0 * (y1[at] + y2[at]);
}

export fn deriche(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 3) return INVALID_RESULT;
    const values = values_opt.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_WIDTH)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_HEIGHT)) or
        values[2] < 1 or values[2] > 4) return INVALID_RESULT;
    const width: usize = @intCast(values[0]);
    const height: usize = @intCast(values[1]);
    var image: [MAX_PIXELS]f32 = [_]f32{0} ** MAX_PIXELS;
    var output: [MAX_PIXELS]f32 = [_]f32{0} ** MAX_PIXELS;
    var y1: [MAX_PIXELS]f32 = [_]f32{0} ** MAX_PIXELS;
    var y2: [MAX_PIXELS]f32 = [_]f32{0} ** MAX_PIXELS;
    for (0..width) |i| for (0..height) |j| {
        image[i * height + j] = @as(f32, @floatFromInt((313 * i + 991 * j) % 65536)) / 65535.0;
    };
    for (0..@intCast(values[2])) |_| {
        filterOnce(width, height, image[0..], output[0..], y1[0..], y2[0..]);
        for (0..width * height) |at| image[at] = output[at];
    }
    var checksum: f64 = 0;
    for (0..width * height) |at| checksum += @as(f64, output[at]);
    return checksum;
}
