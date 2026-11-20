const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;
const MAX_PADDED: usize = MAX_TEXT + MAX_PATTERN;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tuned_boyer_moore_search(input: [*c]const i64, length: usize,
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
        var padded: [MAX_PADDED]u8 = @splat(0);
        var shifts: [128]usize = @splat(m);
        const pattern_start = 2 + n;
        const final_byte: u8 = @intCast(input[pattern_start + m - 1]);
        for (0..n) |i| padded[i] = @intCast(input[2 + i]);
        for (0..m) |i| padded[n + i] = final_byte;
        for (0..m - 1) |i| shifts[@intCast(input[pattern_start + i])] = m - i - 1;
        const final_shift = shifts[final_byte];
        shifts[final_byte] = 0;

        var alignment: usize = 0;
        while (alignment < n) {
            var skip = shifts[padded[alignment + m - 1]];
            while (skip != 0) {
                alignment += skip;
                skip = shifts[padded[alignment + m - 1]];
                alignment += skip;
                skip = shifts[padded[alignment + m - 1]];
                alignment += skip;
                skip = shifts[padded[alignment + m - 1]];
            }
            var prefix_matches = true;
            for (0..m - 1) |i| {
                if (input[pattern_start + i] != padded[alignment + i]) {
                    prefix_matches = false;
                    break;
                }
            }
            if (prefix_matches and alignment < n) {
                positions[match_count] = @intCast(alignment);
                match_count += 1;
            }
            alignment += final_shift;
        }
    }
    const output_bytes = match_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..match_count) |i| storeI64Le(output, i * 8, positions[i]);
    return @intCast(output_bytes);
}
