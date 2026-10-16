const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);

fn hexDigit(byte: i64) i64 {
    if (byte >= 48 and byte <= 57) return byte - 48;
    if (byte >= 65 and byte <= 70) return byte - 65 + 10;
    if (byte >= 97 and byte <= 102) return byte - 97 + 10;
    return -1;
}

pub export fn hex_to_bin(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 5) return INVALID_RESULT;
    var start: usize = 0;
    var sign: i64 = 1;
    if (input[0] == 45) {
        sign = -1;
        start = 1;
    }
    const digit_count = length - start;
    if (digit_count < 1 or digit_count > 4) return INVALID_RESULT;

    var value: i64 = 0;
    for (start..length) |index| {
        const digit = hexDigit(input[index]);
        if (digit < 0) return INVALID_RESULT;
        value = value * 16 + digit;
    }
    if (value == 0) return INVALID_RESULT;

    var decimal_binary_digits: i64 = 0;
    var place: i64 = 1;
    while (value > 0) {
        decimal_binary_digits += (value % 2) * place;
        value /= 2;
        if (value > 0) place *= 10;
    }
    return sign * decimal_binary_digits;
}
