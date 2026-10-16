const max_input_length: usize = 4096;
const max_words: usize = 2049;

fn is_ascii_whitespace(byte: i64) bool {
    return byte == 32 or (byte >= 9 and byte <= 13);
}

export fn remove_duplicate_words(values: [*c]const i64, length: usize,
                                 output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > max_input_length + 1) return -1;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(max_input_length))) return -1;
    const text_length: usize = @intCast(values[0]);
    if (length != text_length + 1) return -1;
    for (0..text_length) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 127) return -1;
    }

    var starts: [max_words]usize = @splat(0);
    var word_lengths: [max_words]usize = @splat(0);
    var word_count: usize = 0;
    var token_start: usize = 0;
    var output_length: usize = 0;
    for (0..text_length + 1) |boundary| {
        if (boundary < text_length and !is_ascii_whitespace(values[boundary + 1])) continue;
        const word_length = boundary - token_start;
        var duplicate = false;
        for (0..word_count) |previous| {
            if (word_lengths[previous] != word_length) continue;
            var offset: usize = 0;
            while (offset < word_length and
                values[1 + starts[previous] + offset] == values[1 + token_start + offset]) offset += 1;
            if (offset == word_length) { duplicate = true; break; }
        }
        if (!duplicate) {
            if (word_count == max_words) return -1;
            starts[word_count] = token_start;
            word_lengths[word_count] = word_length;
            if (word_count > 0) output_length += 1;
            output_length += word_length;
            word_count += 1;
        }
        if (boundary < text_length) token_start = boundary + 1;
    }
    if (output_length > output_capacity or (output_length > 0 and output == null)) return -2;

    var written: usize = 0;
    for (0..word_count) |word| {
        if (word > 0) { output[written] = ' '; written += 1; }
        for (0..word_lengths[word]) |offset| {
            output[written] = @intCast(values[1 + starts[word] + offset]);
            written += 1;
        }
    }
    return @intCast(written);
}
