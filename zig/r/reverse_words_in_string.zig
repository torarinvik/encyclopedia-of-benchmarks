const max_parseable_input_length: usize = 258;

fn isTrimByte(value: i64) bool { return value >= 0 and value <= 32; }
fn isSplitSpace(value: i64) bool { return value == 32 or (value >= 9 and value <= 13); }

export fn reverse_words_in_string(input: [*c]const i64, length: usize,
                                  output: [*c]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > max_parseable_input_length) return -1;
    const values = input[0..length];
    if (values[0] < 0 or values[0] > 256 or length != @as(usize, @intCast(values[0])) + 1) return -1;
    const text_length: usize = @intCast(values[0]);
    for (values[1..]) |value| if (value < 0 or value > 127) return -1;

    var start: usize = 0;
    var end = text_length;
    while (start < end and isTrimByte(values[start + 1])) : (start += 1) {}
    while (end > start and isTrimByte(values[end])) : (end -= 1) {}

    var output_length: usize = 0;
    var word_count: usize = 0;
    var position = start;
    while (position < end) {
        while (position < end and isSplitSpace(values[position + 1])) : (position += 1) {}
        if (position < end) {
            const token_start = position;
            while (position < end and !isSplitSpace(values[position + 1])) : (position += 1) {}
            output_length += position - token_start;
            if (word_count > 0) output_length += 1;
            word_count += 1;
        }
    }
    if (capacity < output_length or (output_length > 0 and output == null)) return -2;

    var written: usize = 0;
    var emitted: usize = 0;
    position = end;
    while (position > start) {
        while (position > start and isSplitSpace(values[position])) : (position -= 1) {}
        if (position > start) {
            const token_end = position;
            while (position > start and !isSplitSpace(values[position])) : (position -= 1) {}
            const token_start = position;
            if (emitted > 0) { output[written] = 32; written += 1; }
            for (token_start..token_end) |i| {
                output[written] = @intCast(values[i + 1]);
                written += 1;
            }
            emitted += 1;
        }
    }
    return @intCast(written);
}
