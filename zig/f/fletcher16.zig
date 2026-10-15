/// Fletcher-16 checksum for bounded ASCII byte arrays.
const MAX_BYTES: usize = 4096;

export fn fletcher16(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_BYTES or (length != 0 and input == null)) return -1;
    var sum1: u32 = 0;
    var sum2: u32 = 0;
    for (0..length) |index| {
        const byte = input[index];
        if (byte < 0 or byte > 127) return -1;
        sum1 = (sum1 + @as(u32, @intCast(byte))) % 255;
        sum2 = (sum2 + sum1) % 255;
    }
    return @intCast((sum2 << 8) | sum1);
}
