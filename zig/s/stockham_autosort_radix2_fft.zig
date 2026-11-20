const std = @import("std");

const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_SCALARS: usize = 128;
const TAU = 6.283185307179586476925286766559;

fn stockham_stage(source: *const [MAX_SCALARS]f64,
                  destination: *[MAX_SCALARS]f64, n: usize, stride: usize) void {
    for (0..n / 2) |j| {
        const column = j % stride;
        const group = j / stride;
        const base = group * 2 * stride + column;
        const angle = -TAU * @as(f64, @floatFromInt(column))
            / @as(f64, @floatFromInt(2 * stride));
        const cosine = @cos(angle);
        const sine = @sin(angle);
        const left = 2 * j;
        const right = 2 * (j + n / 2);
        const product_real = cosine * source[right] - sine * source[right + 1];
        const product_imag = cosine * source[right + 1] + sine * source[right];
        const first_real = source[left];
        const first_imag = source[left + 1];
        const out_left = 2 * base;
        const out_right = 2 * (base + stride);
        destination[out_left] = first_real + product_real;
        destination[out_left + 1] = first_imag + product_imag;
        destination[out_right] = first_real - product_real;
        destination[out_right + 1] = first_imag - product_imag;
    }
}

export fn stockham_autosort_radix2_fft(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT_LENGTH) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const n_value = values[0];
    if (n_value < 1.0 or n_value > @as(f64, @floatFromInt(MAX_N))
        or @floor(n_value) != n_value) return -1;
    const n: usize = @intFromFloat(n_value);
    if ((n & (n - 1)) != 0 or input_length != 1 + 2 * n) return -1;
    for (0..2 * n) |i| if (values[i + 1] < -8.0 or values[i + 1] > 8.0) return -1;

    var first = [_]f64{0.0} ** MAX_SCALARS;
    var second = [_]f64{0.0} ** MAX_SCALARS;
    for (0..2 * n) |i| first[i] = values[i + 1];
    var source_is_first = true;
    var stride: usize = 1;
    while (stride < n) : (stride *= 2) {
        if (source_is_first) {
            stockham_stage(&first, &second, n, stride);
        } else {
            stockham_stage(&second, &first, n, stride);
        }
        source_is_first = !source_is_first;
    }

    const needed = 2 * n;
    const result = output orelse return -2;
    if (output_capacity < needed) return -2;
    for (0..needed) |i| result[i] = if (source_is_first) first[i] else second[i];
    return @intCast(needed);
}
