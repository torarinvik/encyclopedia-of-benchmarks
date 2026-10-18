const std = @import("std");
const MAX_INPUT_LENGTH: usize = 513;
const MAX_LENGTH: usize = 256;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn shuffle(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH or !exactInteger(values[0], 0, MAX_LENGTH)) return -1;
    const count: usize = @intFromFloat(values[0]);
    const offset_count = if (count > 0) count - 1 else 0;
    if (input_length != 1 + count + offset_count) return -1;

    var items = [_]i32{0} ** MAX_LENGTH;
    for (0..count) |index| {
        const value = values[index + 1];
        if (!exactInteger(value, -2147483648.0, 2147483647.0)) return -1;
        items[index] = @intFromFloat(value);
    }
    var offsets = [_]usize{0} ** MAX_LENGTH;
    for (0..offset_count) |index| {
        const value = values[1 + count + index];
        const maximum: f64 = @floatFromInt(count - 1 - index);
        if (!exactInteger(value, 0, maximum)) return -1;
        offsets[index] = @intFromFloat(value);
    }
    for (0..offset_count) |index| {
        const other = index + offsets[index];
        std.mem.swap(i32, &items[index], &items[other]);
    }

    const out = output orelse return -2;
    if (capacity < count) return -2;
    for (0..count) |index| out[index] = @floatFromInt(items[index]);
    return @intCast(count);
}
