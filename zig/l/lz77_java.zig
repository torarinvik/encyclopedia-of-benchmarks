const max_text_length: usize = 64;
const max_input_length: usize = 66;
const max_output_bytes: usize = 1536;

fn putI64Le(output: *[max_output_bytes]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn lz77_java_compress(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > max_input_length) return -1;
    if (values[0] < 0 or values[0] > max_text_length) return -1;
    const text_length: usize = @intCast(values[0]);
    if (input_length != 1 + text_length) return -1;
    for (0..text_length) |index| {
        if (values[index + 1] < 32 or values[index + 1] > 126) return -1;
    }

    var staged = [_]u8{0} ** max_output_bytes;
    var token_count: usize = 0;
    var current: usize = 0;
    while (current < text_length) {
        var best_distance: usize = 0;
        var best_length: usize = 0;
        const search_start = if (current > 4096) current - 4096 else 0;
        const lookahead_end = @min(current + 16, text_length);
        for (search_start..current) |candidate| {
            var match_length: usize = 0;
            while (current + match_length < lookahead_end) {
                var source = candidate + match_length;
                if (source >= current) {
                    const distance = current - candidate;
                    source = candidate + match_length % distance;
                }
                if (values[source + 1] != values[current + match_length + 1]) break;
                match_length += 1;
            }
            if (match_length > best_length) {
                best_distance = current - candidate;
                best_length = match_length;
            }
        }

        const next_character: i64 = if (current + best_length < text_length)
            values[current + best_length + 1]
        else
            0;
        const byte_offset = token_count * 24;
        putI64Le(&staged, byte_offset, @intCast(best_distance));
        putI64Le(&staged, byte_offset + 8, @intCast(best_length));
        putI64Le(&staged, byte_offset + 16, next_character);
        token_count += 1;
        current += if (next_character == 0) best_length else best_length + 1;
    }

    const output_bytes = token_count * 24;
    if (output_bytes > max_output_bytes) return -1;
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;
    if (output_bytes > 0) @memcpy(out[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
