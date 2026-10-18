const std = @import("std");
const MAX_OUTPUT: usize = 6;

export fn pseudo_inverse(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const values = input_opt orelse return -1;
    if (input_length < 3 or input_length > 7) return -1;
    for (0..input_length) |i| { if (!std.math.isFinite(values[i])) return -1; }
    if (@trunc(values[0]) != values[0] or values[0] < 1 or values[0] > 4 or values[1] != 1) return -1;
    const rows: usize = @intFromFloat(values[0]);
    if (input_length != 2 + rows) return -1;
    var column = [_]f64{0} ** 4;
    var squared_norm: f64 = 0;
    for (0..rows) |i| {
        const value = values[2 + i];
        if (@trunc(value) != value or value < -4 or value > 4) return -1;
        column[i] = value;
        squared_norm += value * value;
    }
    var staged = [_]f64{0} ** MAX_OUTPUT;
    staged[0] = 1;
    staged[1] = @floatFromInt(rows);
    if (@sqrt(squared_norm) < 1e-4) {
        for (0..rows) |i| staged[2 + i] = 0;
    } else {
        for (0..rows) |i| staged[2 + i] = column[i] / squared_norm;
    }
    const output_size = rows + 2;
    const output = output_opt orelse return -2;
    if (output_capacity < output_size) return -2;
    @memcpy(output[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
