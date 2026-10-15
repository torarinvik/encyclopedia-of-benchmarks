fn lowercaseAsciiLetter(value: i64) i64 {
    return if (value >= 65 and value <= 90) value + 32 else value;
}

export fn count_letters(input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    if (input[1] < 0 or input[1] > 256) return -1;
    const text_length: usize = @intCast(input[1]);
    if (length != text_length + 2) return -1;
    const query = lowercaseAsciiLetter(input[0]);
    if (query < 97 or query > 122) return -1;
    var count: i64 = 0;
    for (input[2..length]) |value| {
        if (!((value >= 97 and value <= 122) or (value >= 65 and value <= 90))) return -1;
        if (lowercaseAsciiLetter(value) == query) count += 1;
    }
    return count;
}
