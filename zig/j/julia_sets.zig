fn putF32(output: [*]u8, offset: usize, value: f32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn julia_sets(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 68) return -1;
    const values = input.?;
    const iterations, cr_units, ci_units, count_value = .{ values[0], values[1], values[2], values[3] };
    if (iterations < 0 or iterations > 8 or count_value < 0 or count_value > 32) return -1;
    if (cr_units < -128 or cr_units > 128 or ci_units < -128 or ci_units > 128) return -1;
    const count: usize = @intCast(count_value);
    if (length != 4 + 2 * count) return -1;
    for (values[4..length]) |component| if (component < -128 or component > 128) return -1;
    const needed = 8 * count;
    if (output == null or capacity < needed) return -2;
    const out = output.?;
    const cr: f32 = @as(f32, @floatFromInt(cr_units)) / 16.0;
    const ci: f32 = @as(f32, @floatFromInt(ci_units)) / 16.0;
    var computed: [64]f32 = undefined;
    for (0..count) |point| {
        var real: f32 = @as(f32, @floatFromInt(values[4 + 2 * point])) / 16.0;
        var imag: f32 = @as(f32, @floatFromInt(values[5 + 2 * point])) / 16.0;
        for (0..@intCast(iterations)) |_| {
            const real_square = real * real;
            const imag_square = imag * imag;
            const real_imag = real * imag;
            const imag_real = imag * real;
            const next_real = (real_square - imag_square) + cr;
            const next_imag = (real_imag + imag_real) + ci;
            if (!std.math.isFinite(next_real) or !std.math.isFinite(next_imag)) return -1;
            real = next_real;
            imag = next_imag;
        }
        computed[2 * point] = real;
        computed[2 * point + 1] = imag;
    }
    for (0..2 * count) |component| putF32(out, component * 4, computed[component]);
    return @intCast(needed);
}
const std = @import("std");

