const MAX_TEXT_LENGTH: usize = 64;

export fn validate_credit_card(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_TEXT_LENGTH + 1) return -1;
    const raw_length = input[0];
    if (raw_length < 0 or raw_length > MAX_TEXT_LENGTH or length != @as(usize, @intCast(raw_length)) + 1) return -1;
    const n: usize = @intCast(raw_length);
    for (0..n) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 127) return -1;
    }
    if (n < 13 or n > 16) return 0;
    for (0..n) |index| {
        if (input[index + 1] < 48 or input[index + 1] > 57) return 0;
    }
    const first = input[1] - 48;
    const second = input[2] - 48;
    if (!(first == 4 or first == 5 or first == 6 or
        (first == 3 and (second == 4 or second == 5 or second == 7)))) return 0;
    var total: i64 = 0;
    for (0..n) |index| {
        var digit = input[index + 1] - 48;
        if (index % 2 == 0) {
            digit *= 2;
            if (digit > 9) digit -= 9;
        }
        total += digit;
    }
    return if (@mod(total, 10) == 0) 1 else 0;
}
