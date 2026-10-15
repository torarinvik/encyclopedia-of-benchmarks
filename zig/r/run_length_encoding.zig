/// Encode runs as an unambiguous decimal count followed by an ASCII byte.
export fn run_length_encoding(input: [*c]const i64, length: usize,
                              output: [*c]u8, output_capacity: usize) i64 {
    if (length > 66) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 1 or value > 127 or (value >= 48 and value <= 57)) return -1;
    }

    var encoded_length: usize = 0;
    var index: usize = 0;
    while (index < length) {
        var end = index + 1;
        while (end < length and input[end] == input[index]) : (end += 1) {}
        const count = end - index;
        encoded_length += if (count >= 10) 3 else 2;
        index = end;
    }
    if (output_capacity < encoded_length) return -2;

    var write_index: usize = 0;
    index = 0;
    while (index < length) {
        var end = index + 1;
        while (end < length and input[end] == input[index]) : (end += 1) {}
        const count = end - index;
        if (count >= 10) {
            output[write_index] = @intCast(48 + count / 10);
            write_index += 1;
        }
        output[write_index] = @intCast(48 + count % 10);
        write_index += 1;
        output[write_index] = @intCast(input[index]);
        write_index += 1;
        index = end;
    }
    return @intCast(write_index);
}
