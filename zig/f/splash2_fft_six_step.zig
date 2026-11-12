const std = @import("std");

const MAX_POINTS: usize = 64;
const MAX_OUTPUT: usize = 128;
const TAU = 6.283185307179586476925286766559;

fn transpose(source: *const [MAX_OUTPUT]f64, destination: *[MAX_OUTPUT]f64, side: usize) void {
    for (0..side) |row| {
        for (0..side) |column| {
            const from = 2 * (row * side + column);
            const to = 2 * (column * side + row);
            destination[to] = source[from];
            destination[to + 1] = source[from + 1];
        }
    }
}

fn fft_row(data: *[MAX_OUTPUT]f64, base: usize, side: usize) void {
    var reverse: usize = 0;
    for (1..side) |position| {
        var bit = side >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            const left = 2 * (base + position);
            const right = 2 * (base + reverse);
            std.mem.swap(f64, &data[left], &data[right]);
            std.mem.swap(f64, &data[left + 1], &data[right + 1]);
        }
    }
    var block: usize = 2;
    while (block <= side) : (block *= 2) {
        const half = block / 2;
        const angle_step = TAU / @as(f64, @floatFromInt(block));
        var start: usize = 0;
        while (start < side) : (start += block) {
            for (0..half) |offset| {
                const angle = angle_step * @as(f64, @floatFromInt(offset));
                const weight_real = @cos(angle);
                const weight_imag = -@sin(angle);
                const first = 2 * (base + start + offset);
                const second = 2 * (base + start + offset + half);
                const product_real = weight_real * data[second] - weight_imag * data[second + 1];
                const product_imag = weight_real * data[second + 1] + weight_imag * data[second];
                const first_real = data[first];
                const first_imag = data[first + 1];
                data[first] = first_real + product_real;
                data[first + 1] = first_imag + product_imag;
                data[second] = first_real - product_real;
                data[second + 1] = first_imag - product_imag;
            }
        }
    }
}

export fn splash2_fft_six_step(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 9 or input_length > 130) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const side_value = values[0];
    if (side_value != 2.0 and side_value != 4.0 and side_value != 8.0) return -1;
    const side: usize = @intFromFloat(side_value);
    const points = side * side;
    if (input_length != 1 + 2 * points) return -1;
    for (0..2 * points) |i| if (values[i + 1] < -8.0 or values[i + 1] > 8.0) return -1;

    var first_matrix = [_]f64{0} ** MAX_OUTPUT;
    var second_matrix = [_]f64{0} ** MAX_OUTPUT;
    for (0..2 * points) |i| first_matrix[i] = values[i + 1];
    transpose(&first_matrix, &second_matrix, side);
    for (0..side) |row| fft_row(&second_matrix, row * side, side);
    for (0..side) |row| {
        for (0..side) |column| {
            const index = 2 * (row * side + column);
            const angle = TAU * @as(f64, @floatFromInt(row * column)) / @as(f64, @floatFromInt(points));
            const cosine = @cos(angle);
            const sine = @sin(angle);
            const real = second_matrix[index];
            const imag = second_matrix[index + 1];
            second_matrix[index] = cosine * real + sine * imag;
            second_matrix[index + 1] = cosine * imag - sine * real;
        }
    }
    transpose(&second_matrix, &first_matrix, side);
    for (0..side) |row| fft_row(&first_matrix, row * side, side);
    transpose(&first_matrix, &second_matrix, side);

    const needed = 2 * points;
    const out = output orelse return -2;
    if (output_capacity < needed) return -2;
    for (0..needed) |i| out[i] = second_matrix[i];
    return @intCast(needed);
}
