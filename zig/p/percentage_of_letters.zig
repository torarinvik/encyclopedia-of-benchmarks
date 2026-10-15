fn lowerAscii(value: i64) i64 {
    return if (value >= 65 and value <= 90) value + 32 else value;
}

export fn percentage_of_letters(input: ?[*]const i64, length: usize) i64 {
    if (length < 2 or length > 4097 or input == null) return -1;
    const values = input.?[0..length];
    const target = lowerAscii(values[0]);
    if (target < 97 or target > 122) return -1;
    const text = values[1..];
    var matches: usize = 0;
    for (text) |value| {
        if (value < 0 or value > 127) return -1;
        if (lowerAscii(value) == target) matches += 1;
    }
    return @intCast((100 * matches) / text.len);
}
