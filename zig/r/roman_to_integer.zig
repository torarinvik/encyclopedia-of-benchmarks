fn decodeRomanDigit(symbols: [*]const i64, length: usize, position: usize,
                     one: i64, five: i64, ten: i64) i64 {
    if (position >= length) return 0;
    if (symbols[position] == one) {
        if (position + 1 < length and symbols[position + 1] == ten) return 146;
        if (position + 1 < length and symbols[position + 1] == five) return 66;
        var count: usize = 0;
        while (position + count < length and symbols[position + count] == one and count < 3) : (count += 1) {}
        if (position + count < length and symbols[position + count] == one) return -1;
        return @intCast(count * 16 + count);
    }
    if (symbols[position] == five) {
        var count: usize = 0;
        while (position + 1 + count < length and symbols[position + 1 + count] == one and count < 3) : (count += 1) {}
        if (position + 1 + count < length and symbols[position + 1 + count] == one) return -1;
        return @intCast((5 + count) * 16 + 1 + count);
    }
    return 0;
}

/// Decode canonical uppercase Roman numerals in the range 1 through 3,999.
export fn roman_to_integer(symbols: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 15) return -1;
    for (0..length) |index| {
        const symbol = symbols[index];
        if (symbol != 73 and symbol != 86 and symbol != 88 and symbol != 76 and
            symbol != 67 and symbol != 68 and symbol != 77) return -1;
    }
    var position: usize = 0;
    var thousands: usize = 0;
    while (position < length and symbols[position] == 77 and thousands < 3) {
        position += 1;
        thousands += 1;
    }
    if (position < length and symbols[position] == 77) return -1;
    const hundreds = decodeRomanDigit(symbols, length, position, 67, 68, 77);
    if (hundreds < 0) return -1;
    position += @intCast(@mod(hundreds, 16));
    const tens = decodeRomanDigit(symbols, length, position, 88, 76, 67);
    if (tens < 0) return -1;
    position += @intCast(@mod(tens, 16));
    const ones = decodeRomanDigit(symbols, length, position, 73, 86, 88);
    if (ones < 0) return -1;
    position += @intCast(@mod(ones, 16));
    if (position != length) return -1;
    const value = @as(i64, @intCast(thousands)) * 1000 + @divTrunc(hundreds, 16) * 100 +
        @divTrunc(tens, 16) * 10 + @divTrunc(ones, 16);
    if (value < 1 or value > 3999) return -1;
    return value;
}
