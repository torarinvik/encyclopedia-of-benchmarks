export fn snake_case_to_camel_pascal_case(raw: [*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length < 2 or length > 257) return -1;
    if (raw[0] != 0 and raw[0] != 1) return -1;

    const input_length = length - 1;
    var output_length: usize = 0;
    for (0..input_length) |i| {
        const value = raw[i + 1];
        if (value == 95) {
            if (i == 0 or i + 1 == input_length or raw[i] == 95) return -1;
        } else if (!((value >= 97 and value <= 122) or (value >= 48 and value <= 57))) {
            return -1;
        } else {
            output_length += 1;
        }
    }
    if (capacity < output_length) return -2;
    const out = output orelse return -2;

    var position: usize = 0;
    var capitalize = raw[0] == 1;
    for (0..input_length) |i| {
        var value = raw[i + 1];
        if (value == 95) {
            capitalize = true;
            continue;
        }
        if (capitalize and value >= 97 and value <= 122) value -= 32;
        out[position] = @intCast(value);
        position += 1;
        capitalize = false;
    }
    return @intCast(output_length);
}
