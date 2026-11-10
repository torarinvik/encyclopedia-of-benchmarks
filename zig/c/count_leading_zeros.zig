export fn count_leading_zeros(value: i64) i64 {
    if (value < -2147483648 or value > 2147483647) return -1;
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    return @clz(bits);
}
