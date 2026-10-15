/// Case-insensitive anagram check for distinct ASCII alphabetic strings.
const MAX_STRING_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2050;

fn letterIndex(value: i64) ?usize {
    if (value >= 97 and value <= 122) return @intCast(value - 97);
    if (value >= 65 and value <= 90) return @intCast(value - 65);
    return null;
}

export fn check_anagram(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const first_length_value = input[0];
    const second_length_value = input[1];
    if (first_length_value < 0 or first_length_value > MAX_STRING_LENGTH or
        second_length_value < 0 or second_length_value > MAX_STRING_LENGTH) return -1;
    const first_length: usize = @intCast(first_length_value);
    const second_length: usize = @intCast(second_length_value);
    if (length != 2 + first_length + second_length) return -1;
    var first_counts: [26]usize = @splat(0);
    var second_counts: [26]usize = @splat(0);
    for (0..first_length) |index| {
        const letter = letterIndex(input[2 + index]) orelse return -1;
        first_counts[letter] += 1;
    }
    for (0..second_length) |index| {
        const letter = letterIndex(input[2 + first_length + index]) orelse return -1;
        second_counts[letter] += 1;
    }
    if (first_length != second_length) return 0;
    var different_after_normalization = false;
    for (0..first_length) |index| {
        const first = letterIndex(input[2 + index]).?;
        const second = letterIndex(input[2 + first_length + index]).?;
        if (first != second) different_after_normalization = true;
    }
    if (!different_after_normalization) return 0;
    for (0..26) |letter| {
        if (first_counts[letter] != second_counts[letter]) return 0;
    }
    return 1;
}
