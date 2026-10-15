/// Return the first ASCII byte match using bad-character and good-suffix shifts.
export fn boyer_moore(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 8194) return -1;
    if (values[0] < 0 or values[0] > 4096 or values[1] < 0 or values[1] > 4096) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 126) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const pattern_start = 2 + text_length;
    var last_occurrence: [127]i64 = @splat(-1);
    for (0..pattern_length) |index| {
        last_occurrence[@intCast(values[pattern_start + index])] = @intCast(index);
    }

    var good_suffix: [4097]usize = @splat(0);
    var border_position: [4097]usize = @splat(0);
    var i = pattern_length;
    var j = pattern_length + 1;
    border_position[i] = j;
    while (i > 0) {
        while (j <= pattern_length and values[pattern_start + i - 1] != values[pattern_start + j - 1]) {
            if (good_suffix[j] == 0) good_suffix[j] = j - i;
            j = border_position[j];
        }
        i -= 1;
        j -= 1;
        border_position[i] = j;
    }
    j = border_position[0];
    for (0..pattern_length + 1) |index| {
        if (good_suffix[index] == 0) good_suffix[index] = j;
        if (index == j) j = border_position[j];
    }

    var alignment: usize = 0;
    while (alignment <= text_length - pattern_length) {
        var pattern_index = pattern_length;
        while (pattern_index > 0 and
            values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1])
        {
            pattern_index -= 1;
        }
        if (pattern_index == 0) return @intCast(alignment);
        const text_byte: usize = @intCast(values[2 + alignment + pattern_index - 1]);
        const raw_bad_shift = @as(i64, @intCast(pattern_index - 1)) - last_occurrence[text_byte];
        const bad_shift: usize = @intCast(@max(1, raw_bad_shift));
        alignment += @max(good_suffix[pattern_index], bad_shift);
    }
    return -1;
}
