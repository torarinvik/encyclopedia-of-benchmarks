/// Convert most-significant-first binary digits to a signed 64-bit decimal value.
export fn binary_to_decimal(bits: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 63) return -1;
    var value: u64 = 0;
    for (0..length) |index| {
        if (bits[index] != 0 and bits[index] != 1) return -1;
        value = value * 2 + @as(u64, @intCast(bits[index]));
    }
    return @intCast(value);
}
