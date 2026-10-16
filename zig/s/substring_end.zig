const MAX_TEXT_LENGTH: usize = 128;
const CHECKSUM_BASE: i64 = 1_100_000;

export fn substring_end(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_TEXT_LENGTH + 1) return -1;
    const text_length = length - 1;
    const start = values[0];
    if (start < 0 or start > @as(i64, @intCast(text_length))) return -1;
    for (0..text_length) |i| if (values[i + 1] < 1 or values[i + 1] > 127) return -1;
    const count = text_length - @as(usize, @intCast(start));
    var checksum: i64 = 0;
    for (0..count) |i| checksum += @as(i64, @intCast(i + 1)) * values[@as(usize, @intCast(start)) + i + 1];
    return @as(i64, @intCast(count)) * CHECKSUM_BASE + checksum;
}
