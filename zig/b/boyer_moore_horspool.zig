const MAX_INPUT_VALUES: usize = 512;

fn countMatches(values: [*]const i64, text_length: usize, pattern_length: usize,
    pattern_start: usize, shifts: [128]usize) usize {
    if (pattern_length == 0) return text_length + 1;
    if (pattern_length > text_length) return 0;
    var count: usize = 0;
    var start: usize = 0;
    while (start <= text_length - pattern_length) {
        var current = pattern_length;
        while (current > 0 and values[pattern_start + current - 1] == values[2 + start + current - 1]) : (current -= 1) {}
        if (current == 0) {
            count += 1;
            start += 1;
        } else {
            start += shifts[@intCast(values[2 + start + pattern_length - 1])];
        }
    }
    return count;
}

export fn boyer_moore_horspool(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 or values[0] > 255 or values[1] < 0 or values[1] > 255) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    const pattern_start = 2 + text_length;
    for (0..text_length + pattern_length) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 127) return -1;
    }

    var shifts: [128]usize = undefined;
    for (0..128) |byte| shifts[byte] = pattern_length;
    for (0..pattern_length) |index| {
        if (index + 1 < pattern_length) shifts[@intCast(values[pattern_start + index])] = pattern_length - 1 - index;
    }
    const match_count = countMatches(values, text_length, pattern_length, pattern_start, shifts);
    if (output_capacity < match_count) return -2;

    var written: usize = 0;
    if (pattern_length == 0) {
        for (0..text_length + 1) |position| {
            output[written] = @intCast(position);
            written += 1;
        }
    } else if (pattern_length <= text_length) {
        var start: usize = 0;
        while (start <= text_length - pattern_length) {
            var current = pattern_length;
            while (current > 0 and values[pattern_start + current - 1] == values[2 + start + current - 1]) : (current -= 1) {}
            if (current == 0) {
                output[written] = @intCast(start);
                written += 1;
                start += 1;
            } else {
                start += shifts[@intCast(values[2 + start + pattern_length - 1])];
            }
        }
    }
    return @intCast(written);
}
