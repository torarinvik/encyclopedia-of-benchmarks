fn countReversible(remaining: i64, carry_in: i64, digits: *[9]i64, length: i64) i64 {
    if (remaining == 0) {
        if (digits[0] == 0 or digits[@intCast(length - 1)] == 0) return 0;
        var carry = carry_in;
        var i = @divTrunc(length, 2) - 1;
        while (i >= 0) : (i -= 1) {
            carry += digits[@intCast(i)] + digits[@intCast(length - i - 1)];
            if (@rem(carry, 2) == 0) return 0;
            carry = @divTrunc(carry, 10);
        }
        return 1;
    }
    if (remaining == 1) {
        if (@rem(carry_in, 2) == 0) return 0;
        var result: i64 = 0;
        for (0..10) |digit| {
            digits[@intCast(@divTrunc(length, 2))] = @intCast(digit);
            result += countReversible(0, @divTrunc(carry_in + 2 * @as(i64, @intCast(digit)), 10), digits, length);
        }
        return result;
    }
    var result: i64 = 0;
    const right_index: usize = @intCast(@divTrunc(length + remaining, 2) - 1);
    const left_index: usize = @intCast(@divTrunc(length - remaining, 2));
    for (0..10) |digit1| {
        digits[right_index] = @intCast(digit1);
        const parity: usize = if (@rem(carry_in + @as(i64, @intCast(digit1)), 2) == 0) 1 else 0;
        var digit2 = parity;
        while (digit2 < 10) : (digit2 += 2) {
            digits[left_index] = @intCast(digit2);
            result += countReversible(remaining - 2, @divTrunc(carry_in + @as(i64, @intCast(digit1 + digit2)), 10), digits, length);
        }
    }
    return result;
}

export fn problem145(max_power: i64) i64 {
    if (max_power > 9) return -1;
    if (max_power <= 0) return 0;
    var digits = [_]i64{0} ** 9;
    var total: i64 = 0;
    const maximum: usize = @intCast(max_power);
    for (1..(maximum + 1)) |length| {
        if ((length - 1) % 4 != 0) total += countReversible(@intCast(length), 0, &digits, @intCast(length));
    }
    return total;
}
