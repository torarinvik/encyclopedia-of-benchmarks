const MAX_STRING_LENGTH: i64 = 64;
const MAX_INPUT_LENGTH: usize = 3 + 2 * 64;

fn foldAscii(value: i64, mode: i64) i64 {
    if (mode == 1 and value >= 65 and value <= 90) return value + 32;
    return value;
}

export fn comparison(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return -2;
    const packed_values = values[0..length];
    const mode = packed_values[0];
    const first_length_value = packed_values[1];
    if ((mode != 0 and mode != 1) or first_length_value < 0 or first_length_value > MAX_STRING_LENGTH) return -2;
    const first_length: usize = @intCast(first_length_value);
    const second_length_position = 2 + first_length;
    if (second_length_position >= length) return -2;
    const second_length_value = packed_values[second_length_position];
    if (second_length_value < 0 or second_length_value > MAX_STRING_LENGTH) return -2;
    const second_length: usize = @intCast(second_length_value);
    const second_start = second_length_position + 1;
    if (second_start + second_length != length) return -2;
    const first = packed_values[2..second_length_position];
    const second = packed_values[second_start..];
    for (first) |byte| if (byte < 1 or byte > 127) return -2;
    for (second) |byte| if (byte < 1 or byte > 127) return -2;

    const common_length = @min(first_length, second_length);
    for (0..common_length) |index| {
        const left = foldAscii(first[index], mode);
        const right = foldAscii(second[index], mode);
        if (left < right) return -1;
        if (left > right) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}
