const std = @import("std");

const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

fn allowedCoordinate(value: f64) bool {
    return value == 0 or value == 0.25 or value == 0.5 or value == 0.75;
}

export fn montecarlopi(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (!exactInteger(values[0], 1, 64)) return -1;
    const point_count: usize = @intFromFloat(values[0]);
    if (input_length != 1 + 2 * point_count) return -1;
    var inside: usize = 0;
    for (0..point_count) |point| {
        const x = values[1 + 2 * point];
        const y = values[2 + 2 * point];
        if (!allowedCoordinate(x) or !allowedCoordinate(y)) return -1;
        if (x * x + y * y <= 1.0) inside += 1;
    }
    const estimate = @as(f64, @floatFromInt(inside)) / @as(f64, @floatFromInt(point_count)) * 4.0;
    if (!std.math.isFinite(estimate)) return -1;
    const out = output orelse return -2;
    if (capacity < 1) return -2;
    out[0] = estimate;
    return 1;
}
