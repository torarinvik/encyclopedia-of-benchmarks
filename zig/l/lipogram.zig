pub export fn lipogram(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 1026) return -1;
    if (input[0] < 0 or input[0] > 1024 or length != @as(usize, @intCast(input[0])) + 2) return -1;
    const n: usize = @intCast(input[0]);
    const mask = input[length - 1];
    if (mask < 0 or mask > 67108863) return -1;
    var seen: u32 = 0;
    for (0..n) |i| {
        const raw = input[i + 1];
        if (raw < 0 or raw > 127) return -1;
        var ch: u8 = @intCast(raw);
        if (ch >= 'A' and ch <= 'Z') ch += 'a' - 'A';
        if (ch >= 'a' and ch <= 'z') {
            seen |= @as(u32, 1) << @intCast(ch - 'a');
        } else if (ch != 9 and ch != 10 and ch != 11 and ch != 12 and ch != 13 and ch != 32) return -1;
    }
    const alphabet: u32 = (@as(u32, 1) << 26) - 1;
    return if (@as(i64, @intCast(alphabet & ~seen)) == mask) 1 else 0;
}
