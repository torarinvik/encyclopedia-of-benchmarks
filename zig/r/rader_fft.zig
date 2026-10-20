const std = @import("std");

const MAX_COMPONENT: f64 = 100.0;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

fn fft8(real: *[8]f64, imag: *[8]f64, inverse: bool) void {
    const reversed = [_]usize{ 0, 4, 2, 6, 1, 5, 3, 7 };
    for (0..8) |i| {
        const j = reversed[i];
        if (i < j) {
            const tr = real.*[i]; real.*[i] = real.*[j]; real.*[j] = tr;
            const ti = imag.*[i]; imag.*[i] = imag.*[j]; imag.*[j] = ti;
        }
    }
    var stage: usize = 1;
    while (stage <= 3) : (stage += 1) {
        const block = @as(usize, 1) << stage;
        const half = block / 2;
        var start: usize = 0;
        while (start < 8) : (start += block) {
            for (0..half) |j| {
                const sign = if (inverse) 1.0 else -1.0;
                const angle = sign * 2.0 * PI_VALUE * @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(block));
                const wr = @cos(angle);
                const wi = @sin(angle);
                const even = start + j;
                const odd = even + half;
                const ur = real.*[even];
                const ui = imag.*[even];
                const vr = real.*[odd] * wr - imag.*[odd] * wi;
                const vi = real.*[odd] * wi + imag.*[odd] * wr;
                real.*[even] = ur + vr; imag.*[even] = ui + vi;
                real.*[odd] = ur - vr; imag.*[odd] = ui - vi;
            }
        }
    }
    if (inverse) for (0..8) |i| {
        real.*[i] /= 8.0;
        imag.*[i] /= 8.0;
    };
}

export fn rader_fft(input: [*c]const f64, input_length: usize,
                    output: [*c]f64, output_capacity: usize) i64 {
    const permutation = [_]usize{ 1, 2, 4, 3 };
    const kernel_power = [_]usize{ 1, 3, 4, 2 };
    if (input == null or input_length != 10) return -1;
    for (0..10) |i| {
        const value = input[i];
        if (!std.math.isFinite(value) or value < -MAX_COMPONENT or value > MAX_COMPONENT) return -1;
    }
    if (output == null or output_capacity < 10) return -2;

    var ar: [8]f64 = @splat(0.0);
    var ai: [8]f64 = @splat(0.0);
    var br: [8]f64 = @splat(0.0);
    var bi: [8]f64 = @splat(0.0);
    for (0..4) |i| {
        ar[i] = input[2 * permutation[i]];
        ai[i] = input[2 * permutation[i] + 1];
        const angle = -2.0 * PI_VALUE * @as(f64, @floatFromInt(kernel_power[i])) / 5.0;
        br[i] = @cos(angle);
        bi[i] = @sin(angle);
    }
    fft8(&ar, &ai, false);
    fft8(&br, &bi, false);
    for (0..8) |i| {
        const product_real = ar[i] * br[i] - ai[i] * bi[i];
        const product_imag = ar[i] * bi[i] + ai[i] * br[i];
        ar[i] = product_real;
        ai[i] = product_imag;
    }
    fft8(&ar, &ai, true);

    var result: [10]f64 = @splat(0.0);
    for (0..5) |n| {
        result[0] += input[2 * n];
        result[1] += input[2 * n + 1];
    }
    for (1..5) |k| {
        result[2 * k] = input[0];
        result[2 * k + 1] = input[1];
    }
    for (0..4) |i| {
        const target = kernel_power[i];
        result[2 * target] += ar[i] + ar[i + 4];
        result[2 * target + 1] += ai[i] + ai[i + 4];
    }
    for (0..10) |i| output[i] = result[i];
    return 10;
}
