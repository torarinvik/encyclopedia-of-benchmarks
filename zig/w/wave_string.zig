fn isAsciiLetter(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}

pub export fn wave_string(values: [*c]const i64, length: usize,
                          output: [*c]u8, output_capacity: usize) i64 {
    const max_text_length: usize = 512;
    if (values == null or length < 1) return -1;
    if (values[0] < 0 or values[0] > max_text_length or
        length != 1 + @as(usize, @intCast(values[0]))) return -1;
    const text_length: usize = @intCast(values[0]);
    var letter_count: usize = 0;
    for (0..text_length) |index| {
        const byte = values[index + 1];
        if (byte < 32 or byte > 126) return -1;
        if (isAsciiLetter(byte)) letter_count += 1;
    }
    const output_length = letter_count * (text_length + 2);
    if (output_length > output_capacity or (output_length > 0 and output == null)) return -2;

    var written: usize = 0;
    for (0..text_length) |position| {
        if (!isAsciiLetter(values[position + 1])) continue;
        output[written] = @intCast(text_length & 255);
        output[written + 1] = @intCast(text_length >> 8);
        written += 2;
        for (0..text_length) |index| {
            var byte = values[index + 1];
            if (index == position and byte >= 97 and byte <= 122) byte -= 32;
            output[written] = @intCast(byte);
            written += 1;
        }
    }
    return @intCast(letter_count);
}
