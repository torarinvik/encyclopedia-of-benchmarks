const std = @import("std");

const max_draws: usize = 128;
const max_attempts: usize = 64;
const draw_scale: f64 = 2147483648.0;

fn isBoundedInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn marsaglia_polar_normal(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 2 + max_draws) return -1;
    const input = input_opt.?;
    if (!isBoundedInteger(input[0], 2.0, @floatFromInt(max_draws)) or
        !isBoundedInteger(input[1], 1.0, @floatFromInt(max_attempts))) return -1;
    const draw_count: usize = @intFromFloat(input[0]);
    const attempt_cap: usize = @intFromFloat(input[1]);
    if (draw_count % 2 != 0 or length != 2 + draw_count or draw_count < 2 * attempt_cap) return -1;
    for (0..draw_count) |index|
        if (!isBoundedInteger(input[2 + index], 0.0, 4294967295.0)) return -1;

    var first: f64 = 0.0;
    var second: f64 = 0.0;
    var accepted = false;
    for (0..attempt_cap) |attempt| {
        const u1 = input[2 + 2 * attempt] / draw_scale - 1.0;
        const u2 = input[3 + 2 * attempt] / draw_scale - 1.0;
        const radius_squared = u1 * u1 + u2 * u2;
        if (radius_squared <= 0.0 or radius_squared >= 1.0) continue;
        const scale = @sqrt(-2.0 * @log(radius_squared) / radius_squared);
        first = u1 * scale;
        second = u2 * scale;
        accepted = true;
        break;
    }
    if (!accepted) return -1;
    if (output_opt == null or capacity < 2) return -2;
    const output = output_opt.?;
    output[0] = first;
    output[1] = second;
    return 2;
}
