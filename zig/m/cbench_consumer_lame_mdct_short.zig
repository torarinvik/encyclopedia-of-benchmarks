const std = @import("std");

const PI: f64 = 3.14159265358979323846264338327950288;
const ENWINDOW_MAX: f64 = 0.030526638;

export fn cbench_consumer_lame_mdct_short(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    if (input == null or input_length == 0 or input_length > 19) return -1;
    const values = input.?[0..input_length];
    for (values) |value| if (!std.math.isFinite(value) or value < -32768.0 or value > 32768.0) return -1;
    if (input_length != 18) return -1;

    var coefficients: [36]f64 = @splat(0.0);
    const scale = 4.0 / 12.0;
    for (0..3) |i| {
        const w2 = std.math.cos(PI / 12.0 * (@as(f64, @floatFromInt(i)) + 0.5)) * ENWINDOW_MAX / 32768.0 * scale;
        for (0..6) |m| {
            coefficients[6 * m + i] = w2 * std.math.cos((PI / 48.0) * @as(f64, @floatFromInt(2 * m + 1)) * @as(f64, @floatFromInt(4 * i + 14)));
            coefficients[6 * m + i + 3] = w2 * std.math.cos((PI / 48.0) * @as(f64, @floatFromInt(2 * m + 1)) * @as(f64, @floatFromInt(4 * i + 38)));
        }
    }
    var staged: [18]f64 = @splat(0.0);
    var m: i32 = 5;
    while (m >= 0) : (m -= 1) {
        var l: i32 = 2;
        while (l >= 0) : (l -= 1) {
            const row: usize = @intCast(m);
            const col: usize = @intCast(l);
            const base = 6 * col;
            var total = coefficients[6 * row] * values[base];
            for (1..6) |i| total += coefficients[6 * row + i] * values[base + i];
            staged[3 * row + col] = total;
        }
    }
    const result = output orelse return -2;
    if (output_capacity < 18) return -2;
    for (0..18) |i| result[i] = staged[i];
    return 18;
}
