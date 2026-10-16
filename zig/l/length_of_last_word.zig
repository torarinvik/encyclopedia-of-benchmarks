export fn length_of_last_word(input: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > 129 or input == null) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > 128 or length != @as(usize, @intCast(values[0])) + 1) return -1;
    for (1..length) |i| {
        if (values[i] < 0 or values[i] > 255) return -1;
    }
    var index: usize = @intCast(values[0]);
    while (index > 0 and values[index] == 32) index -= 1;
    var word_length: i64 = 0;
    while (index > 0 and values[index] != 32) {
        word_length += 1;
        index -= 1;
    }
    return word_length;
}
