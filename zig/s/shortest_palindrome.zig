/// Add the minimum prefix needed to make a printable ASCII string a palindrome.
const MAX_INPUT_LENGTH: usize = 64;

export fn shortest_palindrome(input: [*c]const i64, length: usize,
                              output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_INPUT_LENGTH) return -1;
    if (length == 0) return 0;
    if (input == null) return -1;
    for (0..length) |i| {
        if (input[i] < 32 or input[i] > 126) return -1;
    }

    var suffix: [64]usize = @splat(0);
    for (1..length) |i| {
        var matched = suffix[i - 1];
        while (matched > 0 and input[matched] != input[i]) matched = suffix[matched - 1];
        if (input[matched] == input[i]) matched += 1;
        suffix[i] = matched;
    }

    var prefix_match: usize = 0;
    for (0..length) |i| {
        const reversed_value = input[length - 1 - i];
        while (prefix_match > 0 and reversed_value != input[prefix_match])
            prefix_match = suffix[prefix_match - 1];
        if (reversed_value == input[prefix_match]) prefix_match += 1;
    }

    const output_length = 2 * length - prefix_match;
    if (output == null or output_capacity < output_length) return -2;
    for (0..length) |i| output[i] = @intCast(input[length - 1 - i]);
    for (prefix_match..length) |i|
        output[length + i - prefix_match] = @intCast(input[i]);
    return @intCast(output_length);
}
