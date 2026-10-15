fn collectMatches(values: [*]const i64, text_length: usize, pattern_length: usize,
    pattern_start: usize, positions: *[255]u8) usize {
    var bad_shift: [128]usize = undefined;
    var present: [128]bool = undefined;
    var suffix_skip: [256]usize = undefined;
    for (0..128) |byte| {
        bad_shift[byte] = 0;
        present[byte] = false;
    }
    for (0..256) |shift| suffix_skip[shift] = 0;
    for (0..pattern_length - 1) |index| {
        const byte: usize = @intCast(values[pattern_start + index]);
        bad_shift[byte] = pattern_length - index - 1;
        present[byte] = true;
    }
    for (0..128) |byte| {
        if (!present[byte]) continue;
        const shift = bad_shift[byte];
        var matched: usize = 0;
        while (matched < pattern_length - shift and
            values[pattern_start + pattern_length - 1 - matched] ==
                values[pattern_start + pattern_length - 1 - shift - matched]) : (matched += 1) {}
        suffix_skip[shift] = matched;
    }

    var count: usize = 0;
    var start: usize = 0;
    var jump = pattern_length;
    while (start <= text_length - pattern_length) {
        const skip = suffix_skip[jump];
        var index: isize = @intCast(pattern_length - 1);
        while (index >= 0) {
            const offset: usize = @intCast(index);
            if (values[2 + start + offset] != values[pattern_start + offset]) {
                const mismatch: usize = @intCast(values[2 + start + offset]);
                jump = if (present[mismatch]) bad_shift[mismatch] else pattern_length;
                start += jump;
                break;
            }
            if (offset == pattern_length - jump) index -= @intCast(skip);
            if (index == 0) {
                positions.*[count] = @intCast(start);
                count += 1;
                jump = 1;
                start += 1;
                break;
            }
            index -= 1;
        }
    }
    return count;
}

export fn boyer_moore_ag(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 512) return -1;
    if (values[0] < 0 or values[0] > 255 or values[1] < 1 or values[1] > 255) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 127) return -1;
    }
    var positions: [255]u8 = undefined;
    const count = if (pattern_length > text_length) 0 else
        collectMatches(values, text_length, pattern_length, 2 + text_length, &positions);
    if (output_capacity < count) return -2;
    for (0..count) |index| output[index] = positions[index];
    return @intCast(count);
}
