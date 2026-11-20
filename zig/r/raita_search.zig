const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn raita_search(input: [*c]const i64, length: usize,
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
        var shifts: [128]usize = @splat(m);
        for (0..m - 1) |i| shifts[@intCast(input[2 + n + i])] = m - i - 1;
        const middle = m / 2;
        var alignment: usize = 0;
        while (alignment <= n - m) {
            const last: usize = @intCast(input[2 + alignment + m - 1]);
            var matches = input[2 + n + m - 1] == input[2 + alignment + m - 1];
            if (matches) matches = input[2 + n] == input[2 + alignment];
            if (matches) matches = input[2 + n + middle] == input[2 + alignment + middle];
            if (matches) {
                var index: usize = 1;
                while (index + 1 < m and matches) : (index += 1) {
                    if (input[2 + n + index] != input[2 + alignment + index]) matches = false;
                }
                if (matches) {
                    positions[match_count] = @intCast(alignment);
                    match_count += 1;
                }
            }
            alignment += shifts[last];
        }
    }
    const output_bytes = match_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..match_count) |i| storeI64Le(output, i * 8, positions[i]);
    return @intCast(output_bytes);
}
