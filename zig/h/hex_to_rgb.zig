fn hexNibble(value: i64) i64 {
    if (value >= 48 and value <= 57) return value - 48;
    if (value >= 65 and value <= 70) return value - 65 + 10;
    if (value >= 97 and value <= 102) return value - 97 + 10;
    return -1;
}

export fn hex_to_rgb(input: [*]const i64, length: usize) i64 {
    if (length != 6) return -1;
    var packed_rgb: i64 = 0;
    for (0..6) |index| {
        const nibble = hexNibble(input[index]);
        if (nibble < 0) return -1;
        packed_rgb = (packed_rgb << 4) | nibble;
    }
    return packed_rgb;
}
