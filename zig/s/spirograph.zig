const std = @import("std");
const MAX_POINTS: usize = 32;
const MAX_OUTPUT_ELEMENTS: usize = 64;
const PI: f64 = 3.14159265358979323846;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn spirograph(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > 5 or input_length != 4 or !exactInteger(values[0], 1, MAX_POINTS)) return -1;
    const points: usize = @intFromFloat(values[0]);
    const marker_ratio = values[1];
    const inner_ratio = values[2];
    const rotations = values[3];
    if (!std.math.isFinite(marker_ratio) or marker_ratio < 0 or marker_ratio > 1 or
        !std.math.isFinite(inner_ratio) or inner_ratio < 0.25 or inner_ratio > 0.75 or
        !std.math.isFinite(rotations) or rotations < 0 or rotations > 10) return -1;

    const delta = rotations * 2.0 * PI / @as(f64, @floatFromInt(points));
    const k1 = 1.0 - inner_ratio;
    var staged = [_]f64{0} ** MAX_OUTPUT_ELEMENTS;
    for (0..points) |index| {
        const t = @as(f64, @floatFromInt(index)) * delta;
        const inner_angle = k1 * t / inner_ratio;
        const x = k1 * @cos(t) + marker_ratio * inner_ratio * @cos(inner_angle);
        const y = k1 * @sin(t) - marker_ratio * inner_ratio * @sin(inner_angle);
        if (!std.math.isFinite(x) or !std.math.isFinite(y)) return -1;
        staged[2 * index] = x;
        staged[2 * index + 1] = y;
    }

    const output_length = 2 * points;
    const out = output orelse return -2;
    if (capacity < output_length) return -2;
    for (0..output_length) |index| out[index] = staged[index];
    return @intCast(output_length);
}
