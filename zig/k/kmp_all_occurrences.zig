const MAX_TEXT_LENGTH: usize = 256;
const MAX_PATTERN_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 322;

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn kmp_all_occurrences(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const text_length_value = values[0];
    const pattern_length_value = values[1];
    if (text_length_value < 0 or text_length_value > @as(i64, @intCast(MAX_TEXT_LENGTH)) or
        pattern_length_value < 1 or pattern_length_value > @as(i64, @intCast(MAX_PATTERN_LENGTH))) return -1;
    const text_length: usize = @intCast(text_length_value);
    const pattern_length: usize = @intCast(pattern_length_value);
    if (length != 2 + text_length + pattern_length) return -1;
    const pattern_offset = 2 + text_length;
    for (0..text_length + pattern_length) |i| {
        const value = values[2 + i];
        if (value < 0 or value > 127) return -1;
    }

    var prefix: [MAX_PATTERN_LENGTH]usize = @splat(0);
    for (1..pattern_length) |i| {
        var matched = prefix[i - 1];
        while (matched > 0 and values[pattern_offset + i] != values[pattern_offset + matched]) {
            matched = prefix[matched - 1];
        }
        if (values[pattern_offset + i] == values[pattern_offset + matched]) matched += 1;
        prefix[i] = matched;
    }

    var matches: [MAX_TEXT_LENGTH]usize = @splat(0);
    var match_count: usize = 0;
    var matched: usize = 0;
    for (0..text_length) |i| {
        while (matched > 0 and values[2 + i] != values[pattern_offset + matched]) {
            matched = prefix[matched - 1];
        }
        if (values[2 + i] == values[pattern_offset + matched]) matched += 1;
        if (matched == pattern_length) {
            matches[match_count] = i + 1 - pattern_length;
            match_count += 1;
            matched = prefix[matched - 1];
        }
    }

    const output_bytes = match_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..match_count) |i| putI64Le(output, i * 8, @intCast(matches[i]));
    return @intCast(output_bytes);
}
