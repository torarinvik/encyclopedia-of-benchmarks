const max_input_length: usize = 64;

export fn ones_complement(input: [*c]const i64, length: usize,
                          output: [*c]u8, capacity: usize) i64 {
    if (length == 0 or length > max_input_length or input == null) return -1;
    for (0..length) |i| {
        if (input[i] != 48 and input[i] != 49) return -1;
    }
    if (length > capacity or output == null) return -2;
    for (0..length) |i| {
        output[i] = if (input[i] == 48) 49 else 48;
    }
    return @intCast(length);
}
