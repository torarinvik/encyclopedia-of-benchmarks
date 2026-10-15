export fn reverse_words(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 256) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    if (output == null or output_capacity < n + 1) return -2;
    for (0..n) |i| {
        const b = values[i + 1];
        if (!(b == 32 or (b >= 33 and b <= 126))) return -1;
        if (b == 32 and (i == 0 or i + 1 == n or values[i] == 32)) return -1;
    }
    const result = output.?[0..output_capacity];
    var written: usize = 0;
    var ending = n;
    while (ending > 0) {
        var start = ending;
        while (start > 0 and values[start] != 32) start -= 1;
        const word_start = start;
        for (word_start..ending) |i| { result[written] = @intCast(values[i + 1]); written += 1; }
        if (word_start == 0) break;
        result[written] = ' '; written += 1;
        ending = start - 1;
    }
    result[written] = 0;
    return @intCast(written);
}
