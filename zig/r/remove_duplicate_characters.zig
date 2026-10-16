const max_input_length: usize = 4096;

export fn remove_duplicate_characters(values: [*c]const i64, length: usize,
                                      output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > max_input_length + 1) return -1;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(max_input_length))) return -1;
    const text_length: usize = @intCast(values[0]);
    if (length != text_length + 1) return -1;
    for (0..text_length) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 127) return -1;
    }

    var seen: [128]bool = @splat(false);
    var output_length: usize = 0;
    for (0..text_length) |index| {
        const byte: usize = @intCast(values[index + 1]);
        if (!seen[byte]) { seen[byte] = true; output_length += 1; }
    }
    if (output_length > output_capacity or (output_length > 0 and output == null)) return -2;

    seen = @splat(false);
    var written: usize = 0;
    for (0..text_length) |index| {
        const byte: usize = @intCast(values[index + 1]);
        if (!seen[byte]) {
            seen[byte] = true;
            output[written] = @intCast(byte);
            written += 1;
        }
    }
    return @intCast(written);
}
