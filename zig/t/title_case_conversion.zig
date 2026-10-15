export fn title_case_conversion(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 256) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        const value = values[i + 1];
        if ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)) continue;
        if (value == 32 and i > 0 and i + 1 < n and values[i] != 32) continue;
        return -1;
    }
    if (output == null or output_capacity < n + 1) return -2;
    const result = output.?[0..output_capacity];
    var at_word_start = true;
    for (0..n) |i| {
        var value = values[i + 1];
        if (value == 32) {
            result[i] = 32;
            at_word_start = true;
        } else if (at_word_start) {
            if (value >= 97 and value <= 122) value -= 32;
            result[i] = @intCast(value);
            at_word_start = false;
        } else {
            if (value >= 65 and value <= 90) value += 32;
            result[i] = @intCast(value);
        }
    }
    result[n] = 0;
    return @intCast(n);
}
