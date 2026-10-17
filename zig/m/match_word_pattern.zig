const MAX_PATTERN_LENGTH: usize = 8;
const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 43;

fn matchWordPatternSearch(
    input: [*c]const i64,
    pattern_length: usize,
    text_start: usize,
    text_length: usize,
    pattern_index: usize,
    text_index: usize,
    mapped_start: *[128]usize,
    mapped_length: *[128]usize,
) bool {
    if (pattern_index == pattern_length) return text_index == text_length;
    if (text_index == text_length) return false;

    const symbol: usize = @intCast(input[2 + pattern_index]);
    const known_length = mapped_length[symbol];
    if (known_length != 0) {
        if (known_length > text_length - text_index) return false;
        for (0..known_length) |offset| {
            if (input[text_start + mapped_start[symbol] + offset]
                != input[text_start + text_index + offset]) return false;
        }
        return matchWordPatternSearch(
            input, pattern_length, text_start, text_length,
            pattern_index + 1, text_index + known_length, mapped_start, mapped_length,
        );
    }

    var end = text_index + 1;
    while (end <= text_length) : (end += 1) {
        const candidate_length = end - text_index;
        var already_used = false;
        for (0..pattern_index) |other_index| {
            const other: usize = @intCast(input[2 + other_index]);
            if (other == symbol) continue;
            if (mapped_length[other] != candidate_length) continue;
            var equal = true;
            for (0..candidate_length) |offset| {
                if (input[text_start + mapped_start[other] + offset]
                    != input[text_start + text_index + offset]) {
                    equal = false;
                    break;
                }
            }
            if (equal) {
                already_used = true;
                break;
            }
        }
        if (already_used) continue;

        mapped_start[symbol] = text_index;
        mapped_length[symbol] = candidate_length;
        if (matchWordPatternSearch(
            input, pattern_length, text_start, text_length,
            pattern_index + 1, end, mapped_start, mapped_length,
        )) return true;
        mapped_length[symbol] = 0;
    }
    return false;
}

export fn match_word_pattern(input: [*c]const i64, input_length: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_PATTERN_LENGTH
        or input[1] < 0 or input[1] > MAX_TEXT_LENGTH) return -1;
    const pattern_length: usize = @intCast(input[0]);
    const text_length: usize = @intCast(input[1]);
    if (input_length != 2 + pattern_length + text_length) return -1;
    const text_start = 2 + pattern_length;
    for (0..pattern_length + text_length) |index| {
        if (input[2 + index] < 0 or input[2 + index] > 127) return -1;
    }

    var mapped_start: [128]usize = [_]usize{0} ** 128;
    var mapped_length: [128]usize = [_]usize{0} ** 128;
    return if (matchWordPatternSearch(
        input, pattern_length, text_start, text_length, 0, 0, &mapped_start, &mapped_length,
    )) 1 else 0;
}
