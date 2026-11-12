const MAX_N: i64 = 100_000;

export fn enumerate_quotients(value: i64, output: ?[*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > MAX_N) return -1;
    const n: u64 = @intCast(value);
    var count: usize = 0;
    var left: u64 = 1;
    while (left <= n) {
        const quotient = n / left;
        count += 1;
        left = n / quotient + 1;
    }
    const byte_count = (count + 1) * 8;
    if (output == null or output_capacity < byte_count) return -2;
    const count_word: u64 = @intCast(count);
    for (0..8) |byte| output.?[byte] = @truncate(count_word >> @intCast(byte * 8));
    var index: usize = 0;
    left = 1;
    while (left <= n) {
        const quotient = n / left;
        for (0..8) |byte| output.?[(index + 1) * 8 + byte] = @truncate(quotient >> @intCast(byte * 8));
        index += 1;
        left = n / quotient + 1;
    }
    return @intCast(byte_count);
}
