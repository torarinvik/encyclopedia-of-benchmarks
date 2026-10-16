const MAX_WIDTH: usize = 64;
const MAX_TEXT_BYTES: usize = 512;
const MAX_WORDS: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + MAX_TEXT_BYTES + 1;
const MAX_OUTPUT_BYTES: usize = MAX_WORDS * MAX_WIDTH + MAX_WORDS;

export fn text_justification(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const width_value = input[0];
    const text_length_value = input[1];
    if (width_value < 1 or width_value > MAX_WIDTH or text_length_value < 0 or text_length_value > MAX_TEXT_BYTES) return -1;
    const width: usize = @intCast(width_value);
    const text_length: usize = @intCast(text_length_value);
    if (length != 2 + text_length) return -1;

    var text: [MAX_TEXT_BYTES]u8 = @splat(0);
    for (0..text_length) |i| {
        const value = input[i + 2];
        if (value != 32 and (value < 33 or value > 126)) return -1;
        text[i] = @intCast(value);
    }
    var starts: [MAX_WORDS]usize = @splat(0);
    var lengths: [MAX_WORDS]usize = @splat(0);
    var word_count: usize = 0;
    var pos: usize = 0;
    while (pos < text_length) {
        while (pos < text_length and text[pos] == ' ') : (pos += 1) {}
        if (pos == text_length) break;
        const start = pos;
        while (pos < text_length and text[pos] != ' ') : (pos += 1) {}
        const word_length = pos - start;
        if (word_count == MAX_WORDS or word_length > width) return -1;
        starts[word_count] = start;
        lengths[word_count] = word_length;
        word_count += 1;
    }

    var result: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var result_length: usize = 0;
    var line_start: usize = 0;
    var line_end: usize = 0;
    var letters: usize = 0;
    var first_line = true;
    for (0..word_count) |word| {
        if (letters + lengths[word] + (line_end - line_start) <= width) {
            letters += lengths[word];
            line_end += 1;
            continue;
        }
        if (!first_line) {
            result[result_length] = '\n';
            result_length += 1;
        }
        first_line = false;
        const count = line_end - line_start;
        if (count == 1) {
            for (0..lengths[line_start]) |i| {
                result[result_length] = text[starts[line_start] + i];
                result_length += 1;
            }
            for (lengths[line_start]..width) |_| {
                result[result_length] = ' ';
                result_length += 1;
            }
        } else {
            const gaps = count - 1;
            const spaces = width - letters;
            const base = spaces / gaps;
            const extra = spaces % gaps;
            for (0..count) |item| {
                const current = line_start + item;
                for (0..lengths[current]) |i| {
                    result[result_length] = text[starts[current] + i];
                    result_length += 1;
                }
                if (item + 1 < count) {
                    const gap_spaces = base + @as(usize, if (item < extra) 1 else 0);
                    for (0..gap_spaces) |_| {
                        result[result_length] = ' ';
                        result_length += 1;
                    }
                }
            }
        }
        line_start = word;
        line_end = word + 1;
        letters = lengths[word];
    }

    if (!first_line) {
        result[result_length] = '\n';
        result_length += 1;
    }
    for (line_start..line_end) |item| {
        if (item != line_start) {
            result[result_length] = ' ';
            result_length += 1;
        }
        for (0..lengths[item]) |i| {
            result[result_length] = text[starts[item] + i];
            result_length += 1;
        }
    }
    const trailing = width - letters - (line_end - line_start) + 1;
    for (0..trailing) |_| {
        result[result_length] = ' ';
        result_length += 1;
    }
    if (capacity < result_length or (result_length != 0 and output == null)) return -2;
    for (0..result_length) |i| output[i] = result[i];
    return @intCast(result_length);
}
