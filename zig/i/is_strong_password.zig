const MAX_INPUT: usize = 258;

export fn is_strong_password(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const values = input.?;
    const minimum_length = values[0];
    const text_length_value = values[1];
    if (minimum_length < 0 or minimum_length > 256 or text_length_value < 0 or text_length_value > 256) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != text_length + 2) return -1;

    var has_uppercase = false;
    var has_lowercase = false;
    var has_digit = false;
    var has_punctuation = false;
    for (0..text_length) |index| {
        const value = values[index + 2];
        if (value < 0 or value > 127) return -1;
        has_uppercase = has_uppercase or (value >= 65 and value <= 90);
        has_lowercase = has_lowercase or (value >= 97 and value <= 122);
        has_digit = has_digit or (value >= 48 and value <= 57);
        has_punctuation = has_punctuation or (value >= 33 and value <= 47) or
            (value >= 58 and value <= 64) or (value >= 91 and value <= 96) or
            (value >= 123 and value <= 126);
    }
    if (text_length_value < minimum_length) return 0;
    if (has_uppercase and has_lowercase and has_digit and has_punctuation) return 1;
    return 0;
}
