/// Rotate a 32-bit word left and return its unsigned value in i64.
export fn rotate_left32(value: u64, shift: u64) i64 {
    if (value > 0xFFFF_FFFF or shift > 0x7FFF_FFFF) return -1;
    const bits: u32 = @intCast(value);
    const amount: u5 = @intCast(shift % 32);
    if (amount == 0) return @intCast(bits);
    const inverse: u5 = @intCast(32 - @as(u32, amount));
    const rotated = (bits << amount) | (bits >> inverse);
    return @intCast(rotated);
}
