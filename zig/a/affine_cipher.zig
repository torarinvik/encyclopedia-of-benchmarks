const MAX_INPUT_VALUES: usize = 612;
const MAX_TEXT_LENGTH: usize = 512;

fn gcdI64(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn inverseMod(value: i64, modulus: i64) i64 {
    var candidate: i64 = 1;
    while (candidate < modulus) : (candidate += 1) {
        if (@rem(value * candidate, modulus) == 1) return candidate;
    }
    return -1;
}

export fn affine_cipher(values: [*]const i64, length: usize,
                       output: [*]u8, output_capacity: usize) i64 {
    if (length < 7 or length > MAX_INPUT_VALUES) return -1;
    const mode = values[0];
    const key_a = values[1];
    const key_b = values[2];
    const alphabet_arg = values[3];
    if (mode < 0 or mode > 1 or alphabet_arg < 2 or alphabet_arg > 95) return -1;
    const alphabet_length: usize = @intCast(alphabet_arg);
    const text_length_index = 4 + alphabet_length;
    if (length <= text_length_index) return -1;
    const text_length_arg = values[text_length_index];
    if (key_a < 0 or key_a > 1_000_000 or key_b < 0 or key_b >= alphabet_arg or
        text_length_arg < 0 or text_length_arg > MAX_TEXT_LENGTH or
        length != text_length_index + 1 + @as(usize, @intCast(text_length_arg)) or
        gcdI64(key_a, alphabet_arg) != 1) return -1;
    const text_length: usize = @intCast(text_length_arg);

    var positions: [128]i16 = @splat(-1);
    for (0..alphabet_length) |index| {
        const symbol = values[4 + index];
        if (symbol < 32 or symbol > 126 or positions[@intCast(symbol)] != -1) return -1;
        positions[@intCast(symbol)] = @intCast(index);
    }
    for (0..text_length) |index| {
        const symbol = values[text_length_index + 1 + index];
        if (symbol < 32 or symbol > 126 or positions[@intCast(symbol)] < 0) return -1;
    }
    if (text_length > output_capacity) return -2;

    const multiplier = @rem(key_a, alphabet_arg);
    const inverse = if (mode == 1) inverseMod(multiplier, alphabet_arg) else 0;
    for (0..text_length) |index| {
        const symbol = values[text_length_index + 1 + index];
        const position: i64 = positions[@intCast(symbol)];
        const mapped = if (mode == 0)
            @rem(position * multiplier + key_b, alphabet_arg)
        else
            @rem(@rem(position - key_b + alphabet_arg, alphabet_arg) * inverse, alphabet_arg);
        output[index] = @intCast(values[4 + @as(usize, @intCast(mapped))]);
    }
    return @intCast(text_length);
}
