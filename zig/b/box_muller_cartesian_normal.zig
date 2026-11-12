const std = @import("std");

const max_pairs: usize = 64;
const draw_scale: f64 = 4_294_967_296.0;
const tau: f64 = 6.283185307179586476925286766559;

fn isBoundedInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn box_muller_cartesian_normal(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 1 + 2 * max_pairs) return -1;
    const input = input_opt.?;
    if (!isBoundedInteger(input[0], 1.0, @floatFromInt(max_pairs))) return -1;
    const pair_count: usize = @intFromFloat(input[0]);
    if (length != 1 + 2 * pair_count) return -1;
    for (0..2 * pair_count) |index|
        if (!isBoundedInteger(input[1 + index], 0.0, 4_294_967_295.0)) return -1;

    const result_count = 2 * pair_count;
    if (output_opt == null or capacity < result_count) return -2;
    const output = output_opt.?;
    for (0..pair_count) |pair| {
        const radial = (input[1 + 2 * pair] + 1.0) / draw_scale;
        const angular = input[2 + 2 * pair] / draw_scale;
        const radius = @sqrt(-2.0 * @log(radial));
        const angle = tau * angular;
        output[2 * pair] = radius * @cos(angle);
        output[2 * pair + 1] = radius * @sin(angle);
    }
    return @intCast(result_count);
}
