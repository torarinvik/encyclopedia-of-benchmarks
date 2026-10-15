/// Decode a reflected Gray-code bit string to a nonnegative binary integer.
export fn gray_to_decimal(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 64) return -1;
    const bit_length = values[0];
    if (bit_length < 1 or bit_length > 63 or length != @as(usize, @intCast(bit_length)) + 1) return -1;

    var prefix: i64 = 0;
    var binary: i64 = 0;
    for (1..length) |index| {
        const character = values[index];
        if (character != 48 and character != 49) return -1;
        prefix ^= character - 48;
        binary = binary * 2 + prefix;
    }
    return binary;
}
