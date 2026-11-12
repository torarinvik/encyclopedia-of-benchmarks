const std = @import("std");

const MAX_POINTS: usize = 64;
const MAX_STEPS: usize = 6;
const CHECKSUM_TERMS: usize = 64;
const TAU = 6.28318530717958647692528676655900577;
const ALPHA = 0.000001;

fn fft_line(real: *[4]f64, imag: *[4]f64, n: usize, inverse: bool) void {
    var reverse: usize = 0;
    for (1..n) |position| {
        var bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            std.mem.swap(f64, &real[position], &real[reverse]);
            std.mem.swap(f64, &imag[position], &imag[reverse]);
        }
    }
    var block: usize = 2;
    while (block <= n) : (block *= 2) {
        const direction = if (inverse) @as(f64, 1.0) else @as(f64, -1.0);
        const angle = direction * TAU / @as(f64, @floatFromInt(block));
        const step_real = @cos(angle);
        const step_imag = @sin(angle);
        var start: usize = 0;
        while (start < n) : (start += block) {
            var weight_real: f64 = 1.0;
            var weight_imag: f64 = 0.0;
            for (0..block / 2) |offset| {
                const first = start + offset;
                const second = first + block / 2;
                const product_real = weight_real * real[second] - weight_imag * imag[second];
                const product_imag = weight_real * imag[second] + weight_imag * real[second];
                const first_real = real[first];
                const first_imag = imag[first];
                real[first] = first_real + product_real;
                imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real;
                imag[second] = first_imag - product_imag;
                const next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
    if (inverse) {
        for (0..n) |i| {
            real[i] /= @as(f64, @floatFromInt(n));
            imag[i] /= @as(f64, @floatFromInt(n));
        }
    }
}

fn line_index(axis: usize, a: usize, b: usize, p: usize, n: usize) usize {
    if (axis == 0) return (p * n + a) * n + b;
    if (axis == 1) return (a * n + p) * n + b;
    return (a * n + b) * n + p;
}

fn axis_transform(real: *[MAX_POINTS]f64, imag: *[MAX_POINTS]f64,
    n: usize, axis: usize, inverse: bool) void {
    for (0..n) |a| {
        for (0..n) |b| {
            var line_real = [_]f64{0} ** 4;
            var line_imag = [_]f64{0} ** 4;
            for (0..n) |p| {
                const index = line_index(axis, a, b, p, n);
                line_real[p] = real[index];
                line_imag[p] = imag[index];
            }
            fft_line(&line_real, &line_imag, n, inverse);
            for (0..n) |p| {
                const index = line_index(axis, a, b, p, n);
                real[index] = line_real[p];
                imag[index] = line_imag[p];
            }
        }
    }
}

fn transform3d(real: *[MAX_POINTS]f64, imag: *[MAX_POINTS]f64, n: usize, inverse: bool) void {
    axis_transform(real, imag, n, 2, inverse);
    axis_transform(real, imag, n, 1, inverse);
    axis_transform(real, imag, n, 0, inverse);
}

fn signed_frequency(index: usize, n: usize) isize {
    return if (index <= n / 2) @intCast(index) else @as(isize, @intCast(index)) - @as(isize, @intCast(n));
}

export fn npb_ft_3d_spectral_step(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > 130) return -1;
    if (values[0] != 2.0 and values[0] != 4.0) return -1;
    if (!std.math.isFinite(values[1]) or values[1] < 1.0 or values[1] > @as(f64, @floatFromInt(MAX_STEPS))) return -1;
    const n: usize = @intFromFloat(values[0]);
    const steps: usize = @intFromFloat(values[1]);
    if (@as(f64, @floatFromInt(steps)) != values[1]) return -1;
    const volume = n * n * n;
    if (input_length != 2 + 2 * volume) return -1;
    for (2..input_length) |i| {
        if (!std.math.isFinite(values[i]) or values[i] < -1.0 or values[i] > 1.0) return -1;
    }
    const needed = 2 * steps;
    const out = output orelse return -2;
    if (output_capacity < needed) return -2;

    var spectrum_real = [_]f64{0} ** MAX_POINTS;
    var spectrum_imag = [_]f64{0} ** MAX_POINTS;
    var work_real = [_]f64{0} ** MAX_POINTS;
    var work_imag = [_]f64{0} ** MAX_POINTS;
    for (0..volume) |i| {
        spectrum_real[i] = values[2 + 2 * i];
        spectrum_imag[i] = values[2 + 2 * i + 1];
    }
    transform3d(&spectrum_real, &spectrum_imag, n, false);
    for (1..steps + 1) |step| {
        for (0..n) |x| {
            for (0..n) |y| {
                for (0..n) |z| {
                    const index = (x * n + y) * n + z;
                    const kx = signed_frequency(x, n);
                    const ky = signed_frequency(y, n);
                    const kz = signed_frequency(z, n);
                    const radius_squared = @as(f64, @floatFromInt(kx * kx + ky * ky + kz * kz));
                    const factor = @exp(-39.47841760435743447533796399950460 * ALPHA * @as(f64, @floatFromInt(step)) * radius_squared);
                    work_real[index] = spectrum_real[index] * factor;
                    work_imag[index] = spectrum_imag[index] * factor;
                }
            }
        }
        transform3d(&work_real, &work_imag, n, true);
        var sum_real: f64 = 0.0;
        var sum_imag: f64 = 0.0;
        for (1..CHECKSUM_TERMS + 1) |j| {
            const x = (j - 1) % n;
            const y = (3 * j - 1) % n;
            const z = (5 * j - 1) % n;
            const index = (x * n + y) * n + z;
            sum_real += work_real[index];
            sum_imag += work_imag[index];
        }
        out[2 * (step - 1)] = sum_real / @as(f64, @floatFromInt(volume));
        out[2 * (step - 1) + 1] = sum_imag / @as(f64, @floatFromInt(volume));
    }
    return @intCast(needed);
}
