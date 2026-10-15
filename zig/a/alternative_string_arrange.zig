/// Interleave two bounded ASCII strings, then append the longer suffix.
export fn alternative_string_arrange(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 64) return -1;
    const first_length: usize = @intCast(values[0]);
    if (1 + first_length >= length or values[1 + first_length] < 0 or values[1 + first_length] > 64) return -1;
    const second_length: usize = @intCast(values[1 + first_length]);
    if (length != 2 + first_length + second_length) return -1;
    const first = values[1 .. 1 + first_length];
    const second = values[2 + first_length .. length];
    for (first) |value| if (value < 0 or value > 127) return -1;
    for (second) |value| if (value < 0 or value > 127) return -1;
    const count = first_length + second_length;
    if (output_capacity < count or (count != 0 and output == null)) return -2;
    if (count == 0) return 0;
    const result = output.?[0..count];
    var written: usize = 0;
    for (0..@max(first_length, second_length)) |i| {
        if (i < first_length) { result[written] = @intCast(first[i]); written += 1; }
        if (i < second_length) { result[written] = @intCast(second[i]); written += 1; }
    }
    return @intCast(written);
}
