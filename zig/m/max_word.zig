const MAX_TEXT_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 2;

fn lowerAscii(value: u8) u8 {
    if (value >= 'A' and value <= 'Z') return value + ('a' - 'A');
    return value;
}

export fn max_word(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const text_length_value = input[0];
    if (text_length_value < 1 or text_length_value > MAX_TEXT_LENGTH) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != 1 + text_length) return -1;

    var text: [MAX_TEXT_LENGTH]u8 = @splat(0);
    for (0..text_length) |i| {
        const value = input[i + 1];
        const is_letter = (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
        if (value == 32) {
            if (i == 0 or i + 1 == text_length or text[i - 1] == ' ') return -1;
        } else if (!is_letter or value == 73) {
            return -1;
        }
        text[i] = @intCast(value);
    }

    var starts: [MAX_TEXT_LENGTH]usize = @splat(0);
    var lengths: [MAX_TEXT_LENGTH]usize = @splat(0);
    var counts: [MAX_TEXT_LENGTH]usize = @splat(0);
    var unique_count: usize = 0;
    var start: usize = 0;
    while (start < text_length) {
        var end = start;
        while (end < text_length and text[end] != ' ') : (end += 1) {}
        const word_length = end - start;
        if (word_length > 6) return -1;
        var found = unique_count;
        for (0..unique_count) |key| {
            if (lengths[key] != word_length) continue;
            var offset: usize = 0;
            while (offset < word_length and
                lowerAscii(text[starts[key] + offset]) == lowerAscii(text[start + offset])) : (offset += 1) {}
            if (offset == word_length) { found = key; break; }
        }
        if (found == unique_count) {
            starts[unique_count] = start;
            lengths[unique_count] = word_length;
            counts[unique_count] = 1;
            unique_count += 1;
        } else {
            counts[found] += 1;
        }
        start = end + 1;
    }

    var winner: usize = 0;
    for (1..unique_count) |key| {
        if (counts[key] > counts[winner]) winner = key;
    }
    const result_length = lengths[winner];
    if (output_capacity < result_length or output == null) return -2;
    const single_word = unique_count == 1 and counts[0] == 1;
    for (0..result_length) |i| {
        const value = text[starts[winner] + i];
        output[i] = if (single_word) value else lowerAscii(value);
    }
    return @intCast(result_length);
}
