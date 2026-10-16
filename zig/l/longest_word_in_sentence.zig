fn isAsciiWhitespace(value: i64) bool {
    return value == 32 or (value >= 9 and value <= 13);
}

pub export fn longest_word_in_sentence(values: [*c]const i64, length: usize,
                                       output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1) return -1;
    if (values[0] < 0 or values[0] > 1024 or
        length != 1 + @as(usize, @intCast(values[0]))) return -1;
    const text_length: usize = @intCast(values[0]);
    for (0..text_length) |index| {
        const byte = values[index + 1];
        if (!isAsciiWhitespace(byte) and (byte < 33 or byte > 126)) return -1;
    }

    var best_start: usize = 0;
    var best_length: usize = 0;
    var index: usize = 0;
    while (index < text_length) {
        if (isAsciiWhitespace(values[index + 1])) { index += 1; continue; }
        const start = index;
        while (index < text_length and !isAsciiWhitespace(values[index + 1])) index += 1;
        const word_length = index - start;
        if (word_length > best_length) {
            best_start = start;
            best_length = word_length;
        }
    }
    if (best_length > output_capacity or (best_length > 0 and output == null)) return -2;
    for (0..best_length) |byte|
        output[byte] = @intCast(values[1 + best_start + byte]);
    return @intCast(best_length);
}
