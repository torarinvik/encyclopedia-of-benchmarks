fn romanDigitLength(digit: i64) usize {
    if (digit == 4 or digit == 9) return 2;
    if (digit >= 5) return @intCast(digit - 4);
    return @intCast(digit);
}

fn appendRomanDigit(digitValue: i64, one: u8, five: u8, ten: u8,
                    output: [*]u8, positionValue: usize) usize {
    var digit = digitValue;
    var position = positionValue;
    if (digit == 9) {
        output[position] = one;
        output[position + 1] = ten;
        return position + 2;
    }
    if (digit >= 5) {
        output[position] = five;
        position += 1;
        digit -= 5;
    }
    if (digit == 4) {
        output[position] = one;
        output[position + 1] = five;
        return position + 2;
    }
    while (digit > 0) : (digit -= 1) {
        output[position] = one;
        position += 1;
    }
    return position;
}

/// Encode an integer in canonical uppercase Roman numerals.
export fn integer_to_roman(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > 3999) return -1;
    const width = @as(usize, @intCast(@divTrunc(value, 1000))) + romanDigitLength(@mod(@divTrunc(value, 100), 10)) +
        romanDigitLength(@mod(@divTrunc(value, 10), 10)) + romanDigitLength(@mod(value, 10));
    if (output_capacity < width) return -2;
    var position: usize = 0;
    for (0..@as(usize, @intCast(@divTrunc(value, 1000)))) |_| {
        output[position] = 'M';
        position += 1;
    }
    position = appendRomanDigit(@mod(@divTrunc(value, 100), 10), 'C', 'D', 'M', output, position);
    position = appendRomanDigit(@mod(@divTrunc(value, 10), 10), 'X', 'L', 'C', output, position);
    position = appendRomanDigit(@mod(value, 10), 'I', 'V', 'X', output, position);
    return @intCast(position);
}
