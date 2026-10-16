const INVALID_RESULT: i64 = -2_147_483_649;

fn hexDigit(code: i64) ?u32 {
    if (code >= 48 and code <= 57) return @intCast(code - 48);
    if (code >= 65 and code <= 70) return @intCast(code - 55);
    if (code >= 97 and code <= 102) return @intCast(code - 87);
    return null;
}

fn signedI32(bits: u32) i64 {
    return if (bits <= 2_147_483_647) @as(i64, bits) else @as(i64, bits) - 4_294_967_296;
}

export fn hex_to_oct(input: ?[*]const i64, length: usize) i64 {
    if (length > 8 or (length != 0 and input == null)) return INVALID_RESULT;
    var decimal_bits: u32 = 0;
    for (0..length) |index| {
        const digit = hexDigit(input.?[index]) orelse return INVALID_RESULT;
        decimal_bits = decimal_bits *% 16 +% digit;
    }
    var decimal = signedI32(decimal_bits);
    if (decimal <= 0) return 0;

    var octal_bits: u32 = 0;
    var place_value: u32 = 1;
    while (decimal > 0) {
        octal_bits +%= @as(u32, @intCast(@mod(decimal, 8))) *% place_value;
        decimal = @divTrunc(decimal, 8);
        place_value *%= 10;
    }
    return signedI32(octal_bits);
}
