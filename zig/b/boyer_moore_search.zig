/// Return the first ASCII byte match using Boyer-Moore's bad-character rule.
export fn boyer_moore_search(input_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 8194) return -1;
    if (input_values[0] < 0 or input_values[0] > 4096 or input_values[1] < 0 or input_values[1] > 4096) return -1;
    const text_length: usize = @intCast(input_values[0]);
    const pattern_length: usize = @intCast(input_values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        if (input_values[2 + index] < 0 or input_values[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const pattern_start = 2 + text_length;
    var last_occurrence: [128]i64 = @splat(-1);
    for (0..pattern_length) |index| {
        last_occurrence[@intCast(input_values[pattern_start + index])] = @intCast(index);
    }
    var alignment: usize = 0;
    while (alignment <= text_length - pattern_length) {
        var pattern_index = pattern_length;
        while (pattern_index > 0 and input_values[pattern_start + pattern_index - 1] == input_values[2 + alignment + pattern_index - 1]) {
            pattern_index -= 1;
        }
        if (pattern_index == 0) return @intCast(alignment);
        const text_byte: usize = @intCast(input_values[2 + alignment + pattern_index - 1]);
        const raw_shift = @as(i64, @intCast(pattern_index - 1)) - last_occurrence[text_byte];
        alignment += @intCast(@max(1, raw_shift));
    }
    return -1;
}
