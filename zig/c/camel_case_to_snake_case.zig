export fn camel_case_to_snake_case(raw: [*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length == 0 or length > 256) return -1;

    var output_length: usize = 0;
    for (0..length) |i| {
        const value = raw[i];
        if (value >= 'A' and value <= 'Z') {
            if (i > 0) output_length += 1;
        } else if (value < 'a' or value > 'z') {
            return -1;
        }
        output_length += 1;
    }
    if (capacity < output_length) return -2;
    const out = output orelse return -2;

    var position: usize = 0;
    for (0..length) |i| {
        const value = raw[i];
        if (value >= 'A' and value <= 'Z') {
            if (i > 0) {
                out[position] = '_';
                position += 1;
            }
            out[position] = @intCast(value + ('a' - 'A'));
        } else {
            out[position] = @intCast(value);
        }
        position += 1;
    }
    return @intCast(output_length);
}
