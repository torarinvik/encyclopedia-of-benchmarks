const MAX_LENGTH: usize = 4096;

fn isTrimCharacter(value: i64) bool { return value <= 32; }
fn isRegexWhitespace(value: i64) bool {
    return value == 9 or value == 10 or value == 11 or value == 12 or value == 13 or value == 32;
}

/// Count tokens after Java String.trim() and split("\\s+").
export fn count_words(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    if (length == 0) return 0;
    const data = values[0..length];
    for (data) |value| {
        if (value < 0 or value > 127) return -1;
    }
    var start: usize = 0;
    var ending = length;
    while (start < ending and isTrimCharacter(data[start])) : (start += 1) {}
    while (ending > start and isTrimCharacter(data[ending - 1])) : (ending -= 1) {}
    if (start == ending) return 1;
    var count: i64 = 0;
    var in_word = false;
    for (data[start..ending]) |value| {
        if (isRegexWhitespace(value)) {
            in_word = false;
        } else if (!in_word) {
            count += 1;
            in_word = true;
        }
    }
    return count;
}
