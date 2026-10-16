fn compare_words(values: [*c]const i64, start_a: usize, length_a: usize,
                 start_b: usize, length_b: usize) i32 {
    const common = @min(length_a, length_b);
    for (0..common) |index| {
        const a = values[1 + start_a + index];
        const b = values[1 + start_b + index];
        if (a < b) return -1;
        if (a > b) return 1;
    }
    if (length_a < length_b) return -1;
    if (length_a > length_b) return 1;
    return 0;
}

pub export fn remove_duplicate(values: [*c]const i64, length: usize,
                               output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1) return -1;
    if (values[0] < 0 or values[0] > 1024 or length != 1 + @as(usize, @intCast(values[0]))) return -1;
    const text_length: usize = @intCast(values[0]);
    for (0..text_length) |index| {
        const byte = values[index + 1];
        if (byte != 32 and (byte < 97 or byte > 122)) return -1;
    }
    var starts: [512]usize = @splat(0);
    var word_lengths: [512]usize = @splat(0);
    var word_count: usize = 0;
    var cursor: usize = 0;
    while (cursor < text_length) {
        if (values[cursor + 1] == 32) { cursor += 1; continue; }
        starts[word_count] = cursor;
        while (cursor < text_length and values[cursor + 1] != 32) cursor += 1;
        word_lengths[word_count] = cursor - starts[word_count];
        word_count += 1;
    }
    if (word_count > 1) {
        for (1..word_count) |index| {
            const key_start = starts[index];
            const key_length = word_lengths[index];
            var position = index;
            while (position > 0 and compare_words(values, starts[position - 1], word_lengths[position - 1],
                                                  key_start, key_length) > 0) {
                starts[position] = starts[position - 1];
                word_lengths[position] = word_lengths[position - 1];
                position -= 1;
            }
            starts[position] = key_start;
            word_lengths[position] = key_length;
        }
    }
    var output_length: usize = 0;
    var unique_count: usize = 0;
    for (0..word_count) |index| {
        if (index > 0 and compare_words(values, starts[index - 1], word_lengths[index - 1],
                                        starts[index], word_lengths[index]) == 0) continue;
        if (unique_count > 0) output_length += 1;
        output_length += word_lengths[index];
        unique_count += 1;
    }
    if (output_length > output_capacity or (output_length > 0 and output == null)) return -2;
    var written: usize = 0;
    var emitted: usize = 0;
    for (0..word_count) |index| {
        if (index > 0 and compare_words(values, starts[index - 1], word_lengths[index - 1],
                                        starts[index], word_lengths[index]) == 0) continue;
        if (emitted > 0) { output[written] = ' '; written += 1; }
        for (0..word_lengths[index]) |byte| {
            output[written] = @intCast(values[1 + starts[index] + byte]);
            written += 1;
        }
        emitted += 1;
    }
    return @intCast(output_length);
}
