export fn binary_to_hex(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (length > 4096 or (length != 0 and values == null)) return -1;
    const input = if (values) |ptr| ptr[0..length] else &[_]i64{};
    for (input) |bit| {
        if (bit != 48 and bit != 49) return -1;
    }

    const output_length = (length + 3) / 4;
    if (output_length == 0) return 0;
    if (output == null or output_capacity < output_length) return -2;
    const result = output.?[0..output_length];

    var first_width = length % 4;
    if (first_width == 0) first_width = 4;
    var start: usize = 0;
    for (0..output_length) |group| {
        const width = if (group == 0) first_width else 4;
        var nibble: i64 = 0;
        for (0..width) |offset| {
            nibble = nibble * 2 + (input[start + offset] - 48);
        }
        result[group] = @intCast(if (nibble < 10) 48 + nibble else 55 + nibble);
        start += width;
    }
    return @intCast(output_length);
}
