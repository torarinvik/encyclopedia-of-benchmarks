const INPUT_BYTES: usize = 5;
const SEGMENT_MASKS = [_]u8{0x00,0x24,0x5d,0x6d,0x2e,0x5d,0x7b,0x25,0x7f,0x6f,0x3f,0x7a,0x53,0x7c,0x5b,0x1b};

export fn beebs_lcdnum(values: [*c]const i64, length: usize,
                       output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != INPUT_BYTES) return -1;
    for (0..INPUT_BYTES) |i| {
        if (values[i] < 0 or values[i] > 255) return -1;
    }
    if (output == null or capacity < INPUT_BYTES) return -2;
    for (0..INPUT_BYTES) |i| {
        output[i] = SEGMENT_MASKS[@intCast(values[i] & 0x0f)];
    }
    return @intCast(INPUT_BYTES);
}
