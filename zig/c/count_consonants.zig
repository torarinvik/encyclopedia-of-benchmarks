const MAX_LENGTH: usize = 4096;

export fn count_consonants(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_LENGTH) return -1;
    const input = values.?;
    if (length == 1 and input[0] == 48) return -1;
    var count: i64 = 0;
    for (0..length) |index| {
        var value = input[index];
        if (value < 32 or value > 126) return -1;
        if (value >= 65 and value <= 90) value += 32;
        if (value >= 97 and value <= 122 and value != 97 and value != 101 and value != 105 and value != 111 and value != 117) count += 1;
    }
    return count;
}
