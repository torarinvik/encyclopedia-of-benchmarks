export fn alaw_encode(input: i64) i64 {
    if (input < -32768 or input > 32767) return -1;
    const sample: i32 = @intCast(input);
    const sign: i32 = if (sample < 0) 0x80 else 0;
    const magnitude: i32 = if (sample < 0) -sample - 1 else sample;
    var segment: i32 = 7;
    var mask: i32 = 0x4000;
    while ((magnitude & mask) == 0 and segment > 0) {
        segment -= 1;
        mask >>= 1;
    }
    const shift: u5 = if (segment != 0) @intCast(segment + 3) else 4;
    const quantization = (magnitude >> shift) & 0x0f;
    return @intCast((sign | (segment << 4) | quantization) ^ 0xD5);
}
