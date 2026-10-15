export fn horspool_search(input_values: [*]const i64, length: usize) i64 {
    if (length < 2) return -2;
    const text_length_value = input_values[0];
    const pattern_length_value = input_values[1];
    if (text_length_value < 0 or text_length_value > 512 or pattern_length_value < 0 or pattern_length_value > 64) return -2;
    const text_length: usize = @intCast(text_length_value);
    const pattern_length: usize = @intCast(pattern_length_value);
    if (length != text_length + pattern_length + 2) return -2;
    const pattern_start = 2 + text_length;
    for (input_values[2..pattern_start]) |byte| {
        if (byte < 0 or byte > 127) return -2;
    }
    for (input_values[pattern_start..length]) |byte| {
        if (byte < 0 or byte > 127) return -2;
    }
    if (pattern_length == 0 or pattern_length > text_length) return -1;
    var shifts: [128]usize = @splat(pattern_length);
    var index = pattern_length - 1;
    while (index > 0) : (index -= 1) {
        const byte: usize = @intCast(input_values[pattern_start + index - 1]);
        if (shifts[byte] == pattern_length) shifts[byte] = pattern_length - index;
    }
    var end_index = pattern_length - 1;
    while (end_index < text_length) {
        var offset: usize = 0;
        while (offset < pattern_length
            and input_values[pattern_start + pattern_length - 1 - offset] == input_values[2 + end_index - offset]) : (offset += 1) {}
        if (offset == pattern_length) return @intCast(end_index - pattern_length + 1);
        const byte: usize = @intCast(input_values[2 + end_index]);
        end_index += shifts[byte];
    }
    return -1;
}
