export fn binary_length(value: i64) i64 {
    if (value <= 0 or value > 2147483647) return -1;
    return @as(i64, @intFromFloat(@floor(@log2(@as(f64, @floatFromInt(value)))))) + 1;
}
