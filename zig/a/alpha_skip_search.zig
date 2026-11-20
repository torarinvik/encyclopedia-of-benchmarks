const MAX_TEXT_LENGTH: usize = 4096;
const MAX_PATTERN_LENGTH: usize = 128;
const MAX_BUCKETS: usize = 64;
const MAX_INPUT_LENGTH: usize = 4227;

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const text_length64 = input[0];
    const pattern_length64 = input[1];
    if (text_length64 < 0 or text_length64 > MAX_TEXT_LENGTH
        or pattern_length64 < 1 or pattern_length64 > MAX_PATTERN_LENGTH) return null;
    const text_length: usize = @intCast(text_length64);
    const pattern_length: usize = @intCast(pattern_length64);
    if (input.len != 2 + text_length + pattern_length) return null;

    var text: [MAX_TEXT_LENGTH]u8 = @splat(0);
    var pattern: [MAX_PATTERN_LENGTH]u8 = @splat(0);
    for (0..text_length) |i| {
        const symbol = input[2 + i];
        if (symbol < 0 or symbol > 3) return null;
        text[i] = @intCast(symbol);
    }
    const pattern_offset = 2 + text_length;
    for (0..pattern_length) |i| {
        const symbol = input[pattern_offset + i];
        if (symbol < 0 or symbol > 3) return null;
        pattern[i] = @intCast(symbol);
    }

    var factor_length: usize = 1;
    var bucket_count: usize = 4;
    while (bucket_count * 4 <= pattern_length) {
        bucket_count *= 4;
        factor_length += 1;
    }
    const factor_count = pattern_length - factor_length + 1;
    var factor_power: usize = 1;
    for (1..factor_length) |_| factor_power *= 4;
    var heads: [MAX_BUCKETS]i16 = @splat(-1);
    var next_position: [MAX_PATTERN_LENGTH]i16 = undefined;
    var code: usize = 0;
    for (0..factor_length) |i| code = code * 4 + @as(usize, pattern[i]);
    for (0..factor_count) |position| {
        if (position > 0) {
            code = (code - @as(usize, pattern[position - 1]) * factor_power) * 4
                + @as(usize, pattern[position + factor_length - 1]);
        }
        next_position[position] = heads[code];
        heads[code] = @intCast(position);
    }
    if (text_length < pattern_length) return 0;

    const shift = pattern_length - factor_length + 1;
    var match_count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    var sample_start: usize = 0;
    while (sample_start <= text_length - factor_length) : (sample_start += shift) {
        var text_code: usize = 0;
        for (0..factor_length) |offset| text_code = text_code * 4 + @as(usize, text[sample_start + offset]);
        var pattern_position = heads[text_code];
        while (pattern_position >= 0) {
            const candidate = @as(isize, @intCast(sample_start)) - @as(isize, pattern_position);
            if (candidate >= 0 and @as(usize, @intCast(candidate)) <= text_length - pattern_length) {
                const start: usize = @intCast(candidate);
                var matches = true;
                for (0..pattern_length) |offset| {
                    if (text[start + offset] != pattern[offset]) {
                        matches = false;
                        break;
                    }
                }
                if (matches) {
                    match_count += 1;
                    offset_sum += @intCast(start);
                    offset_xor ^= @intCast(start);
                }
            }
            pattern_position = next_position[@intCast(pattern_position)];
        }
    }
    return (match_count << 36) | (offset_sum << 12) | offset_xor;
}

export fn alpha_skip_search(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
