const MAX_TEXT_LENGTH: usize = 128;
const CHECKSUM_BASE: i64 = 1_100_000;

export fn substring_minus(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_TEXT_LENGTH) return -1;
    for (0..length) |i| if (values[i] < 1 or values[i] > 127) return -1;
    const count = length - 1;
    var checksum: i64 = 0;
    for (0..count) |i| checksum += @as(i64, @intCast(i + 1)) * values[i];
    return @as(i64, @intCast(count)) * CHECKSUM_BASE + checksum;
}
