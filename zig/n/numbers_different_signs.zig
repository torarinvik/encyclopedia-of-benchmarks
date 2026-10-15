const std = @import("std");

/// Return whether the signed 32-bit XOR has its sign bit set.
export fn numbers_different_signs(left: i64, right: i64) i64 {
    if (left < std.math.minInt(i32) or left > std.math.maxInt(i32) or
        right < std.math.minInt(i32) or right > std.math.maxInt(i32)) return -1;
    const left_value: i32 = @intCast(left);
    const right_value: i32 = @intCast(right);
    return if ((left_value ^ right_value) < 0) 1 else 0;
}
