export fn string_compression(input: [*c]const i64, length: usize,
                             output: [*c]u8, output_capacity: usize) i64 {
    if (length > 64 or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 0 or value > 127) return -1;
    }

    var encoded_length: usize = 0;
    var index: usize = 0;
    while (index < length) {
        var end = index + 1;
        while (end < length and input[end] == input[index]) : (end += 1) {}
        const count = end - index;
        encoded_length += 1;
        if (count > 1) encoded_length += if (count >= 10) 2 else 1;
        index = end;
    }
    if (output_capacity < encoded_length or (encoded_length != 0 and output == null)) return -2;

    var write_index: usize = 0;
    index = 0;
    while (index < length) {
        var end = index + 1;
        while (end < length and input[end] == input[index]) : (end += 1) {}
        const count = end - index;
        output[write_index] = @intCast(input[index]);
        write_index += 1;
        if (count > 1) {
            if (count >= 10) {
                output[write_index] = @intCast(48 + count / 10);
                write_index += 1;
            }
            output[write_index] = @intCast(48 + count % 10);
            write_index += 1;
        }
        index = end;
    }
    return @intCast(write_index);
}
