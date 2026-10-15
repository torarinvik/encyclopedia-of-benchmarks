const std = @import("std");

/// Return the first index with equal left and right sums.
pub export fn equilibrium_index_in_array(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 1025) return -2;
    const n = values[0];
    if (n < 0 or n > 1024 or length != @as(usize, @intCast(n)) + 1) return -2;
    var total: i64 = 0;
    for (values[1..length]) |value| {
        if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return -2;
        total += value;
    }
    var left: i64 = 0;
    for (0..@as(usize, @intCast(n))) |index| {
        const value = values[index + 1];
        total -= value;
        if (left == total) return @intCast(index);
        left += value;
    }
    return -1;
}
