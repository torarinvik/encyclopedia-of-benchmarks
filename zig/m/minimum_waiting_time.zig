const std = @import("std");

export fn minimum_waiting_time(values: [*c]const i64, length: usize) i64 {
    if (length > 64) return std.math.minInt(i64);
    if (length == 0) return 0;
    if (values == null) return std.math.minInt(i64);
    var durations: [64]i64 = @splat(0);
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 1000) return std.math.minInt(i64);
        durations[index] = value;
    }
    for (1..length) |index| {
        const key = durations[index];
        var cursor = index;
        while (cursor > 0 and durations[cursor - 1] > key) {
            durations[cursor] = durations[cursor - 1];
            cursor -= 1;
        }
        durations[cursor] = key;
    }
    var total: i64 = 0;
    for (0..length) |index| {
        total += durations[index] * @as(i64, @intCast(length - index - 1));
    }
    return total;
}
