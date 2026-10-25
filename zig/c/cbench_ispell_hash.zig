const MAX_WORD_BYTES: usize = 64;
fn upperAscii(c: u32) u32 { return if (c >= 97 and c <= 122) c - 32 else c; }
pub export fn cbench_ispell_hash(values: [*c]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_WORD_BYTES + 1) return -1;
    const table_size = values[0];
    if (table_size < 1 or table_size > 2_147_483_647) return -1;
    const count = length - 1;
    for (0..count) |i| if (values[i + 1] < 1 or values[i + 1] > 127) return -1;
    var h: u32 = 0;
    const initial = @min(count, 4);
    for (0..initial) |i| h = (h << 8) | upperAscii(@intCast(values[i + 1]));
    for (initial..count) |i| h = ((h << 5) | (h >> 27)) ^ upperAscii(@intCast(values[i + 1]));
    return @intCast(@as(u64, h) % @as(u64, @intCast(table_size)));
}
