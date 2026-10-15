/// Check for a permutation of one lowercase ASCII string inside another.
const MAX_STRING_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;

fn adjustCount(differences: *[26]i64, nonzero: *i64, letter: usize, amount: i64) void {
    if (differences[letter] == 0) nonzero.* += 1;
    differences[letter] += amount;
    if (differences[letter] == 0) nonzero.* -= 1;
}

export fn permutation_in_string(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const first_length_value = input[0];
    const second_length_value = input[1];
    if (first_length_value < 0 or first_length_value > MAX_STRING_LENGTH or
        second_length_value < 0 or second_length_value > MAX_STRING_LENGTH) return -1;
    const first_length: usize = @intCast(first_length_value);
    const second_length: usize = @intCast(second_length_value);
    if (length != 2 + first_length + second_length) return -1;
    for (2..length) |index| {
        const value = input[index];
        if (value < 97 or value > 122) return -1;
    }
    if (first_length > second_length) return 0;

    var differences: [26]i64 = @splat(0);
    var nonzero: i64 = 0;
    for (0..first_length) |index| {
        const pattern = input[2 + index];
        const window = input[2 + first_length + index];
        adjustCount(&differences, &nonzero, @intCast(pattern - 97), 1);
        adjustCount(&differences, &nonzero, @intCast(window - 97), -1);
    }
    if (nonzero == 0) return 1;
    for (0..second_length - first_length) |start| {
        const outgoing = input[2 + first_length + start];
        const incoming = input[2 + first_length + start + first_length];
        adjustCount(&differences, &nonzero, @intCast(outgoing - 97), 1);
        adjustCount(&differences, &nonzero, @intCast(incoming - 97), -1);
        if (nonzero == 0) return 1;
    }
    return 0;
}
