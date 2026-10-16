const MAX_TEXT_LENGTH: usize = 128;
const MAX_REQUESTED_COUNT: i64 = 64;
const CHECKSUM_BASE: i64 = 300_000;

export fn substring_st_char(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_TEXT_LENGTH + 2) return -1;
    const target = values[0];
    const requested = values[1];
    const text_length = length - 2;
    if (target < 1 or target > 127 or requested < 0 or requested > MAX_REQUESTED_COUNT) return -1;
    for (0..text_length) |i| if (values[i + 2] < 1 or values[i + 2] > 127) return -1;
    var start: usize = 0;
    while (start < text_length and values[start + 2] != target) : (start += 1) {}
    if (start == text_length) return -1;
    const remaining = text_length - start;
    var count: usize = @intCast(requested);
    if (count == 0) count = 1;
    if (count > remaining) count = remaining;
    var checksum: i64 = 0;
    for (0..count) |i| checksum += @as(i64, @intCast(i + 1)) * values[start + i + 2];
    return @as(i64, @intCast(count)) * CHECKSUM_BASE + checksum;
}
