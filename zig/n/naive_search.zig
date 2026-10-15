export fn naive_search(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 512) return -1;
    if (values[0] < 0 or values[0] > 255 or values[1] < 0 or values[1] > 255) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    const pattern_start = 2 + text_length;
    for (0..text_length) |index| {
        if (values[2 + index] < 1 or values[2 + index] > 127) return -1;
    }
    for (0..pattern_length) |index| {
        if (values[pattern_start + index] < 1 or values[pattern_start + index] > 127) return -1;
    }

    var match_count: usize = 0;
    if (pattern_length <= text_length) {
        for (0..(text_length - pattern_length + 1)) |start| {
            var offset: usize = 0;
            while (offset < pattern_length and values[2 + start + offset] == values[pattern_start + offset]) : (offset += 1) {}
            if (offset == pattern_length) match_count += 1;
        }
    }
    if (output_capacity < match_count) return -2;
    var written: usize = 0;
    if (pattern_length <= text_length) {
        for (0..(text_length - pattern_length + 1)) |start| {
            var offset: usize = 0;
            while (offset < pattern_length and values[2 + start + offset] == values[pattern_start + offset]) : (offset += 1) {}
            if (offset == pattern_length) {
                output[written] = @intCast(start);
                written += 1;
            }
        }
    }
    return @intCast(written);
}
