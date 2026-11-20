const MAX_TEXT: usize = 64;
const MAX_WORDS: usize = 16;
const MAX_WORD_LENGTH: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = 211;

export fn maximum_matching_word_segmentation(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const values = input.?[0..length];
    const text_length_value = values[0];
    const word_count_value = values[1];
    if (text_length_value < 0 or text_length_value > @as(i64, @intCast(MAX_TEXT)) or
        word_count_value < 0 or word_count_value > @as(i64, @intCast(MAX_WORDS))) return -1;
    const text_length: usize = @intCast(text_length_value);
    const word_count: usize = @intCast(word_count_value);
    if (length < 2 + text_length) return -1;
    for (0..text_length) |position| {
        if (values[2 + position] < 97 or values[2 + position] > 122) return -1;
    }

    var word_offsets: [MAX_WORDS]usize = undefined;
    var word_lengths: [MAX_WORDS]usize = undefined;
    var cursor: usize = 2 + text_length;
    for (0..word_count) |word| {
        if (cursor >= length) return -1;
        const word_length_value = values[cursor];
        cursor += 1;
        if (word_length_value < 1 or word_length_value > @as(i64, @intCast(MAX_WORD_LENGTH))) return -1;
        const word_length: usize = @intCast(word_length_value);
        if (word_length > length - cursor) return -1;
        word_offsets[word] = cursor;
        word_lengths[word] = word_length;
        for (0..word_length) |offset| {
            if (values[cursor + offset] < 97 or values[cursor + offset] > 122) return -1;
        }
        cursor += word_length;
    }
    if (cursor != length) return -1;

    var token_ids: [MAX_TEXT]u8 = @splat(0);
    var token_count: usize = 0;
    var position: usize = 0;
    while (position < text_length) {
        var best_length: usize = 0;
        var best_id: u8 = 0;
        for (0..word_count) |word| {
            const candidate_length = word_lengths[word];
            if (candidate_length <= best_length or candidate_length > text_length - position) continue;
            var offset: usize = 0;
            while (offset < candidate_length and values[word_offsets[word] + offset] == values[2 + position + offset]) : (offset += 1) {}
            if (offset == candidate_length) {
                best_length = candidate_length;
                best_id = @intCast(word + 1);
            }
        }
        token_ids[token_count] = best_id;
        token_count += 1;
        position += if (best_length == 0) 1 else best_length;
    }

    const output_length = token_count + 1;
    if (output == null or capacity < output_length) return -2;
    const bytes = output.?[0..output_length];
    bytes[0] = @intCast(token_count);
    @memcpy(bytes[1..], token_ids[0..token_count]);
    return @intCast(output_length);
}
