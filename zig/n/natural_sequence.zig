const std = @import("std");

export fn natural_sequence(index: i64) i64 {
    if (index < 0 or index == std.math.maxInt(i64)) return -1;
    return index + 1;
}
