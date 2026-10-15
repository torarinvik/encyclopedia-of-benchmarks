export fn alaw_decode(input: i64) i64 {
    if (input < 0 or input > 255) return -1;
    const alaw: i32 = @as(i32, @intCast(input)) ^ 0xD5;
    const sign = alaw & 0x80;
    const segment = (alaw & 0x70) >> 4;
    var sample = ((alaw & 0x0F) << 4) | 8;
    if (segment != 0) sample += 0x100;
    const shift: u5 = if (segment > 1) @intCast(segment - 1) else 0;
    sample <<= shift;
    return if (sign != 0) -sample else sample;
}
