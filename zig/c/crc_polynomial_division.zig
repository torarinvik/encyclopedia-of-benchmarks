export fn crc_polynomial_division(input: ?[*]const i64, length: usize,
                                 output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 3 + 64 + 16) return -1;
    const values = input.?[0..length];
    const operation = values[0];
    const raw_message_length = values[1];
    const raw_polynomial_length = values[2];
    if (operation < 0 or operation > 1 or raw_message_length < 1 or raw_message_length > 64
        or raw_polynomial_length < 2 or raw_polynomial_length > 16) return -1;
    const message_length: usize = @intCast(raw_message_length);
    const polynomial_length: usize = @intCast(raw_polynomial_length);
    if (length != 3 + message_length + polynomial_length) return -1;

    var message: [64]u8 = @splat(0);
    var polynomial: [16]u8 = @splat(0);
    var dividend: [79]u8 = @splat(0);
    var remainder: [16]u8 = @splat(0);
    for (0..message_length) |i| {
        if (values[3 + i] < 0 or values[3 + i] > 1) return -1;
        message[i] = @intCast(values[3 + i]);
    }
    for (0..polynomial_length) |i| {
        const bit = values[3 + message_length + i];
        if (bit < 0 or bit > 1) return -1;
        polynomial[i] = @intCast(bit);
    }
    if (polynomial[0] != 1 or polynomial[polynomial_length - 1] != 1) return -1;

    var dividend_length = message_length;
    @memcpy(dividend[0..message_length], message[0..message_length]);
    if (operation == 0) {
        for (0..polynomial_length - 1) |_| { dividend[dividend_length] = 0; dividend_length += 1; }
    }
    var remainder_length: usize = 0;
    var cursor: usize = 0;
    while (cursor < dividend_length) {
        while (remainder_length < polynomial_length and cursor < dividend_length) {
            remainder[remainder_length] = dividend[cursor];
            remainder_length += 1;
            cursor += 1;
        }
        if (remainder_length == polynomial_length) {
            if (remainder[0] == 1) for (0..polynomial_length) |i| { remainder[i] ^= polynomial[i]; };
            var leading_zeroes: usize = 0;
            while (leading_zeroes < remainder_length and remainder[leading_zeroes] == 0) : (leading_zeroes += 1) {}
            for (leading_zeroes..remainder_length) |i| remainder[i - leading_zeroes] = remainder[i];
            remainder_length -= leading_zeroes;
        }
    }

    const output_length = if (operation == 0) message_length + remainder_length else 1;
    if (output == null or capacity < output_length) return -2;
    const result = output.?[0..output_length];
    if (operation == 0) {
        @memcpy(result[0..message_length], message[0..message_length]);
        @memcpy(result[message_length..], remainder[0..remainder_length]);
    } else {
        var nonzero: u8 = 0;
        for (remainder[0..remainder_length]) |bit| nonzero |= bit;
        result[0] = @intFromBool(nonzero != 0);
    }
    return @intCast(output_length);
}
