fn decimalLength(valueInput: i64) usize {
    var value = valueInput;
    var length: usize = 1;
    while (value >= 10) : (length += 1) { value = @divTrunc(value, 10); }
    return length;
}

fn appendDecimal(valueInput: i64, output: [*]u8, positionInput: usize) usize {
    var digits: [3]u8 = undefined;
    var count: usize = 0;
    var value = valueInput;
    while (true) {
        digits[count] = @intCast(@rem(value, 10));
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    var position = positionInput;
    while (count > 0) {
        count -= 1;
        output[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

export fn euler_totient_sequence(n: i64, output: [*]u8, output_capacity: usize) i64 {
    if (n < 1 or n > 80) return -1;
    const limit: usize = @intCast(n);
    var phi: [81]i64 = @splat(0);
    for (1..limit + 1) |value| {
        var remaining = value;
        var totient: i64 = @intCast(value);
        var p: usize = 2;
        while (p * p <= remaining) : (p += 1) {
            if (remaining % p == 0) {
                while (remaining % p == 0) { remaining /= p; }
                totient -= @divTrunc(totient, @as(i64, @intCast(p)));
            }
        }
        if (remaining > 1) totient -= @divTrunc(totient, @as(i64, @intCast(remaining)));
        phi[value] = totient;
    }
    var required: usize = limit - 1;
    for (1..limit + 1) |i| required += decimalLength(phi[i]);
    if (output_capacity < required) return -2;
    var position: usize = 0;
    for (1..limit + 1) |i| {
        if (i > 1) { output[position] = ','; position += 1; }
        position = appendDecimal(phi[i], output, position);
    }
    return @intCast(position);
}
