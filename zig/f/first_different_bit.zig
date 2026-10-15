const std = @import("std");

/// Return the trailing-zero count of the signed 32-bit XOR.
export fn first_different_bit(x: i64, y: i64) i64 {
    if (x < std.math.minInt(i32) or x > std.math.maxInt(i32) or
        y < std.math.minInt(i32) or y > std.math.maxInt(i32)) return -1;
    const difference: u32 = @as(u32, @bitCast(@as(i32, @intCast(x)))) ^
                             @as(u32, @bitCast(@as(i32, @intCast(y))));
    return @as(i64, @intCast(@ctz(difference)));
}
