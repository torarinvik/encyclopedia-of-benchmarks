/// Return the one-based position of the least significant set bit.
export fn rightmost_set_bit(value: i64) i64 {
    if (value <= 0 or value > 2_147_483_647) return -1;
    const unsigned: u32 = @intCast(value);
    const lowest = unsigned & (0 -% unsigned);
    return @as(i64, @intCast(@ctz(lowest))) + 1;
}
