fn digitCounts(value_in: i64) [10]u8 {
    var counts = [_]u8{0} ** 10;
    var value = value_in;
    while (value > 0) { counts[@intCast(@rem(value, 10))] += 1; value = @divTrunc(value, 10); }
    return counts;
}
fn sameDigits(left: i64, right: i64) bool {
    const a = digitCounts(left);
    const b = digitCounts(right);
    return std.mem.eql(u8, &a, &b);
}
const std = @import("std");

export fn problem52(unused: i64) i64 {
    if (unused != 0) return -1;
    var value: i64 = 1;
    while (true) : (value += 1) {
        var matches = true;
        var multiplier: i64 = 2;
        while (multiplier <= 6 and matches) : (multiplier += 1) { matches = sameDigits(value, value * multiplier); }
        if (matches) return value;
    }
}
