const std = @import("std");

const max_n: usize = 64;
const max_steps: usize = 8;
const max_input_length: usize = 2 + 4 * max_n;
const tau: f64 = 6.28318530717958647692528676655900577;

fn boundedInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

fn fft(real: *[max_n]f64, imag: *[max_n]f64, n: usize, inverse: bool) void {
    var reverse: usize = 0;
    for (1..n) |position| {
        var bit = n >> 1;
        while (bit != 0 and (reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            const temp_real = real.*[position]; real.*[position] = real.*[reverse]; real.*[reverse] = temp_real;
            const temp_imag = imag.*[position]; imag.*[position] = imag.*[reverse]; imag.*[reverse] = temp_imag;
        }
    }
    var block: usize = 2;
    while (block <= n) : (block *= 2) {
        const direction: f64 = if (inverse) 1.0 else -1.0;
        const angle = direction * tau / @as(f64, @floatFromInt(block));
        const step_real = @cos(angle);
        const step_imag = @sin(angle);
        var start: usize = 0;
        while (start < n) : (start += block) {
            var weight_real: f64 = 1.0;
            var weight_imag: f64 = 0.0;
            for (0..block / 2) |offset| {
                const first = start + offset;
                const second = first + block / 2;
                const product_real = weight_real * real.*[second] - weight_imag * imag.*[second];
                const product_imag = weight_real * imag.*[second] + weight_imag * real.*[second];
                const first_real = real.*[first];
                const first_imag = imag.*[first];
                real.*[first] = first_real + product_real;
                imag.*[first] = first_imag + product_imag;
                real.*[second] = first_real - product_real;
                imag.*[second] = first_imag - product_imag;
                const next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
    if (inverse) {
        const divisor: f64 = @floatFromInt(n);
        for (0..n) |i| { real.*[i] /= divisor; imag.*[i] /= divisor; }
    }
}

fn normalize(real: *[max_n]f64, imag: *[max_n]f64, n: usize) void {
    var norm_squared: f64 = 0.0;
    for (0..n) |i| norm_squared += real.*[i] * real.*[i] + imag.*[i] * imag.*[i];
    const norm = @sqrt(norm_squared);
    for (0..n) |i| { real.*[i] /= norm; imag.*[i] /= norm; }
}

export fn split_operator_imaginary_time(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_length) return -1;
    const input = input_opt.?;
    if (!boundedInteger(input[0], 2.0, @floatFromInt(max_n))
        or !boundedInteger(input[1], 0.0, @floatFromInt(max_steps))) return -1;
    const n: usize = @intFromFloat(input[0]);
    const steps: usize = @intFromFloat(input[1]);
    if (n & (n - 1) != 0 or length != 2 + 4 * n) return -1;
    const momentum_start = 2 + n;
    const state_start = 2 + 2 * n;
    var norm_squared: f64 = 0.0;
    for (0..n) |i| {
        const position = input[2 + i];
        const momentum = input[momentum_start + i];
        const real_value = input[state_start + 2 * i];
        const imag_value = input[state_start + 2 * i + 1];
        if (!std.math.isFinite(position) or position < 0.25 or position > 1.0
            or !std.math.isFinite(momentum) or momentum < 0.25 or momentum > 1.0
            or !std.math.isFinite(real_value) or @abs(real_value) > 1.0
            or !std.math.isFinite(imag_value) or @abs(imag_value) > 1.0) return -1;
        norm_squared += real_value * real_value + imag_value * imag_value;
    }
    if (!(norm_squared > 0.0)) return -1;
    const output_count = 2 * n;
    if (output_opt == null or capacity < output_count) return -2;

    var real: [max_n]f64 = @splat(0.0);
    var imag: [max_n]f64 = @splat(0.0);
    for (0..n) |i| {
        real[i] = input[state_start + 2 * i];
        imag[i] = input[state_start + 2 * i + 1];
    }
    normalize(&real, &imag, n);
    for (0..steps) |_| {
        for (0..n) |i| { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        fft(&real, &imag, n, false);
        for (0..n) |i| {
            real[i] *= input[momentum_start + i];
            imag[i] *= input[momentum_start + i];
        }
        fft(&real, &imag, n, true);
        for (0..n) |i| { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        normalize(&real, &imag, n);
    }
    const output = output_opt.?;
    for (0..n) |i| { output[2 * i] = real[i]; output[2 * i + 1] = imag[i]; }
    return @intCast(output_count);
}
