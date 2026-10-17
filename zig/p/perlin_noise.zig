const std = @import("std");
const MAX_DIMENSION: usize = 8;
const MAX_INPUT_ELEMENTS: usize = 5;
const MAX_PARSEABLE_INPUT_ELEMENTS: usize = 6;
const MAX_OUTPUT_ELEMENTS: usize = MAX_DIMENSION * MAX_DIMENSION;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = (1 << 48) - 1;

fn roundedAdd(a: f32, b: f32) f32 { return a + b; }
fn roundedSub(a: f32, b: f32) f32 { return a - b; }
fn roundedMul(a: f32, b: f32) f32 { return a * b; }
fn roundedDiv(a: f32, b: f32) f32 { return a / b; }

fn javaNext(state: *u64, bits: u6) u32 {
    state.* = (state.* *% JAVA_MULTIPLIER +% JAVA_ADDEND) & JAVA_MASK;
    return @intCast(state.* >> (48 - bits));
}

fn interpolate(a: f32, b: f32, alpha: f32) f32 {
    const one_minus_alpha = roundedSub(1.0, alpha);
    const left = roundedMul(a, one_minus_alpha);
    const right = roundedMul(alpha, b);
    return roundedAdd(left, right);
}

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and value >= minimum and value <= maximum and @trunc(value) == value;
}

export fn perlin_noise(input_opt: ?[*]const f64, length: usize, output_opt: ?[*]f64, output_capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_PARSEABLE_INPUT_ELEMENTS) return -1;
    if (length != MAX_INPUT_ELEMENTS) return -1;
    const input = input_opt.?;
    if (!exactInteger(input[0], 1, 8) or !exactInteger(input[1], 1, 8) or
        !exactInteger(input[2], 1, 4) or !exactInteger(input[4], 0, 2147483647) or
        (input[3] != 0.5 and input[3] != 0.75 and input[3] != 1.0)) return -1;

    const width: usize = @intFromFloat(input[0]);
    const height: usize = @intFromFloat(input[1]);
    const octave_count: usize = @intFromFloat(input[2]);
    const seed: u64 = @intFromFloat(input[4]);
    const count = width * height;
    var base: [MAX_OUTPUT_ELEMENTS]f32 = [_]f32{0} ** MAX_OUTPUT_ELEMENTS;
    var layers: [4 * MAX_OUTPUT_ELEMENTS]f32 = [_]f32{0} ** (4 * MAX_OUTPUT_ELEMENTS);
    var result: [MAX_OUTPUT_ELEMENTS]f32 = [_]f32{0} ** MAX_OUTPUT_ELEMENTS;

    var state = (seed ^ JAVA_MULTIPLIER) & JAVA_MASK;
    for (0..width) |x| for (0..height) |y| {
        base[x * height + y] = roundedDiv(@floatFromInt(javaNext(&state, 24)), 16777216.0);
    };

    for (0..octave_count) |octave| {
        const period = @as(usize, 1) << @intCast(octave);
        const frequency = roundedDiv(1.0, @floatFromInt(period));
        const offset = octave * MAX_OUTPUT_ELEMENTS;
        for (0..width) |x| {
            const x0 = (x / period) * period;
            const x1 = (x0 + period) % width;
            const horizontal = roundedMul(@floatFromInt(x - x0), frequency);
            for (0..height) |y| {
                const y0 = (y / period) * period;
                const y1 = (y0 + period) % height;
                const vertical = roundedMul(@floatFromInt(y - y0), frequency);
                const top = interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal);
                const bottom = interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal);
                layers[offset + x * height + y] = interpolate(top, bottom, vertical);
            }
        }
    }

    const persistence: f32 = @floatCast(input[3]);
    var amplitude: f32 = 1.0;
    var total_amplitude: f32 = 0.0;
    var octave = octave_count;
    while (octave > 0) {
        octave -= 1;
        amplitude = roundedMul(amplitude, persistence);
        total_amplitude = roundedAdd(total_amplitude, amplitude);
        const offset = octave * MAX_OUTPUT_ELEMENTS;
        for (0..count) |i| result[i] = roundedAdd(result[i], roundedMul(layers[offset + i], amplitude));
    }
    const inverse_total = roundedDiv(1.0, total_amplitude);
    for (0..count) |i| result[i] = roundedMul(result[i], inverse_total);

    if (output_opt == null or output_capacity < count) return -2;
    const output = output_opt.?;
    for (0..count) |i| output[i] = @floatCast(result[i]);
    return @intCast(count);
}
