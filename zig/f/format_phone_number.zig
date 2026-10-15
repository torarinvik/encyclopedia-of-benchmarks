export fn format_phone_number(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (values == null or length != 10) return -1;
    const input = values.?[0..length];
    for (input) |digit| {
        if (digit < 48 or digit > 57) return -1;
    }
    if (output == null or output_capacity < 14) return -2;
    const result = output.?[0..output_capacity];

    result[0] = '(';
    for (0..3) |index| result[index + 1] = @intCast(input[index]);
    result[4] = ')';
    result[5] = ' ';
    for (0..3) |index| result[index + 6] = @intCast(input[index + 3]);
    result[9] = '-';
    for (0..4) |index| result[index + 10] = @intCast(input[index + 6]);
    return 14;
}
