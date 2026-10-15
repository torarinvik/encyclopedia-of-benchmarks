/// Compare lowercase ASCII strings by their letter frequencies.
const MAX_STRING_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;

export fn valid_anagram(input: [*]const i64, length: usize) i64 {
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
        const value = input[2 + index];
        if (value < 97 or value > 122) return -1;
        first_counts[@intCast(value - 97)] += 1;
    }
    for (0..second_length) |index| {
        const value = input[2 + first_length + index];
        if (value < 97 or value > 122) return -1;
        second_counts[@intCast(value - 97)] += 1;
    }
    for (0..26) |letter| {
        if (first_counts[letter] != second_counts[letter]) return 0;
    }
    return 1;
}
