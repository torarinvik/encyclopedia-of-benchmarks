const MAX_TEXT_LENGTH: usize = 64;

/// Validate an ASCII card string using the source prefix and Luhn rules.
export fn credit_card_validator(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_TEXT_LENGTH + 1) return -1;
    const values = input[0..length];
    const n = values[0];
    if (n < 0 or n > MAX_TEXT_LENGTH or length != @as(usize, @intCast(n)) + 1) return -1;
    for (values[1..]) |ch| if (ch < 0 or ch > 127) return -1;
    for (values[1..]) |ch| if (ch < 48 or ch > 57) return 0;
    if (n < 13 or n > 16) return 0;
    const first = values[1] - 48;
    const second = values[2] - 48;
    if (!(first == 4 or first == 5 or first == 6 or (first == 3 and (second == 4 or second == 5 or second == 7)))) return 0;
    var sum: i64 = 0;
    for (values[1..], 0..) |ch, i| {
        var digit = ch - 48;
        if (@as(i64, @intCast(i % 2)) == @mod(n, 2)) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return if (@mod(sum, 10) == 0) 1 else 0;
}
