const std = @import("std");

export fn mutate(input: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const mu = input[0];
    const count_value = input[1];
    if (!std.math.isFinite(mu) or mu < 0.0 or mu > 1.0 or !std.math.isFinite(count_value) or
        @floor(count_value) != count_value or count_value < 0.0 or count_value > 64.0) return -1;
    const count: usize = @intFromFloat(count_value);
    if (length != 2 + 2 * count) return -1;
    for (0..count) |index| {
        const gene = input[2 + index];
        if (gene != 0.0 and gene != 1.0) return -1;
    }
    for (0..count) |index| {
        const draw = input[2 + count + index];
        if (!std.math.isFinite(draw) or draw < 0.0 or draw >= 1.0) return -1;
    }
    if (output == null or capacity < count) return -2;
    for (0..count) |index| {
        const gene = input[2 + index];
        const draw = input[2 + count + index];
        output[index] = if (draw < mu) 1.0 - gene else gene;
    }
    return @intCast(count);
}
