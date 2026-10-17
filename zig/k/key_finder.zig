const MAX_TEXT_LENGTH: i64 = 256;
const MAX_INPUT_LENGTH: usize = 258;
const WORD_BANK = [_][]const u8{
    "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
    "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
    " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be ",
};

fn shiftAsciiLetter(code: i64, key: i64) i64 {
    if (code >= 65 and code <= 90) return 65 + @mod(code - 65 + key, 26);
    if (code >= 97 and code <= 122) return 97 + @mod(code - 97 + key, 26);
    return code;
}

export fn key_finder(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const text_length_value = values[0];
    if (text_length_value < 0 or text_length_value > MAX_TEXT_LENGTH) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != text_length + 1) return -1;
    for (0..text_length) |index| {
        const code = values[index + 1];
        if (code < 32 or code > 126 or (code >= 48 and code <= 57)) return -1;
    }

    for (0..26) |key_index| {
        const key: i64 = @intCast(key_index);
        for (0..text_length) |start| {
            for (WORD_BANK) |phrase| {
                if (start + phrase.len > text_length) continue;
                var offset: usize = 0;
                while (offset < phrase.len) : (offset += 1) {
                    const expected: i64 = @intCast(phrase[offset]);
                    if (shiftAsciiLetter(values[start + offset + 1], key) != expected) break;
                }
                if (offset == phrase.len) return key;
            }
        }
    }
    return 0;
}
