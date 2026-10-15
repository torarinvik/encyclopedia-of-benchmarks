const std = @import("std");

const MAX_N: i64 = 8;
const MAX_P: i64 = 6;
const INVALID_RESULT: f64 = -1.0e300;

export fn minkowski_distance(packed: [*]const i64, length: usize) f64 {
    if (length < 2 or length > 18) return INVALID_RESULT;
    const n = packed[0];
    const p = packed[1];
    if (n < 0 or n > MAX_N or p < 3 or p > MAX_P or length != @as(usize, @intCast(2 + 2 * n))) return INVALID_RESULT;
    for (0..@as(usize, @intCast(n))) |index| {
        if (packed[2 + index] < -100 or packed[2 + index] > 100 or
            packed[2 + @as(usize, @intCast(n)) + index] < -100 or packed[2 + @as(usize, @intCast(n)) + index] > 100) return INVALID_RESULT;
    }
    var total: i64 = 0;
    for (0..@as(usize, @intCast(n))) |index| {
        var difference = packed[2 + index] - packed[2 + @as(usize, @intCast(n)) + index];
        if (difference < 0) difference = -difference;
        var term: i64 = 1;
        for (0..@as(usize, @intCast(p))) |_| term *= difference;
        total += term;
    }
    return std.math.pow(f64, @as(f64, @floatFromInt(total)), 1.0 / @as(f64, @floatFromInt(p)));
}
