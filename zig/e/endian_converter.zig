const INVALID_RESULT: i64 = -2_147_483_649;
/// Reverse the byte order of a signed 32-bit integer.
export fn endian_converter(value: i64) i64 {
    if (value < -2_147_483_648 or value > 2_147_483_647) return INVALID_RESULT;
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    const reversed = ((bits & 0x000000ff) << 24) | ((bits & 0x0000ff00) << 8) |
                     ((bits & 0x00ff0000) >> 8) | ((bits & 0xff000000) >> 24);
    return @as(i32, @bitCast(reversed));
}
