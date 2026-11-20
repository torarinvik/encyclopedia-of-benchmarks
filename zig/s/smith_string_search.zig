const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn smith_string_search(input: [*c]const i64, length: usize,
        output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_FRAME) return -1;
    if (input[0] < 0 or input[0] > MAX_TEXT or input[1] < 1 or input[1] > MAX_PATTERN) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |i| {
        if (input[2 + i] < 0 or input[2 + i] > 127) return -1;
    }

    var positions: [MAX_TEXT]i64 = @splat(0);
    var match_count: usize = 0;
    if (m <= n) {
        const pattern_start = 2 + n;
        var horspool: [128]usize = @splat(m);
        var quick_search: [128]usize = @splat(m + 1);
        for (0..m - 1) |i| horspool[@intCast(input[pattern_start + i])] = m - i - 1;
        for (0..m) |i| quick_search[@intCast(input[pattern_start + i])] = m - i;

        const last_alignment = n - m;
        var alignment: usize = 0;
        while (alignment <= last_alignment) {
            var matches = true;
            for (0..m) |i| {
                if (input[pattern_start + i] != input[2 + alignment + i]) {
                    matches = false;
                    break;
                }
            }
            if (matches) {
                positions[match_count] = @intCast(alignment);
                match_count += 1;
            }
            const end_byte: usize = @intCast(input[2 + alignment + m - 1]);
            const lookahead = alignment + m;
            const quick_shift = if (lookahead < n) quick_search[@intCast(input[2 + lookahead])] else m + 1;
            const end_shift = horspool[end_byte];
            alignment += @max(end_shift, quick_shift);
        }
    }
    const output_bytes = match_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..match_count) |i| storeI64Le(output, i * 8, positions[i]);
    return @intCast(output_bytes);
}
