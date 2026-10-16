const max_input_length: usize = 4096;

export fn swap_case(input: [*c]const i64, length: usize,
                    output: [*c]u8, capacity: usize) i64 {
    if (length > max_input_length or (length != 0 and input == null)) return -1;
    for (0..length) |i| {
        if (input[i] < 0 or input[i] > 127) return -1;
    }
    if (length > capacity or (length != 0 and output == null)) return -2;
    for (0..length) |i| {
        var value = input[i];
        if (value >= 65 and value <= 90) value += 32
        else if (value >= 97 and value <= 122) value -= 32;
        output[i] = @intCast(value);
    }
    return @intCast(length);
}
