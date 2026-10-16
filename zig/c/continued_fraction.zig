const max_coefficients: usize = 32;

fn gcdPositive(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn continued_fraction(input: [*c]const i64, length: usize,
        output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    var numerator = input[0];
    var denominator = input[1];
    if (numerator < -1000000 or numerator > 1000000 or denominator < -1000000 or
        denominator > 1000000 or denominator == 0) return -1;
    const abs_numerator = if (numerator < 0) -numerator else numerator;
    const abs_denominator = if (denominator < 0) -denominator else denominator;
    const divisor = gcdPositive(abs_numerator, abs_denominator);
    numerator = @divTrunc(numerator, divisor);
    denominator = @divTrunc(denominator, divisor);
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }

    var coefficients: [max_coefficients]i64 = @splat(0);
    var count: usize = 0;
    while (true) {
        var quotient = @divTrunc(numerator, denominator);
        var remainder = @rem(numerator, denominator);
        if (remainder < 0) { quotient -= 1; remainder += denominator; }
        if (count == max_coefficients) return -1;
        coefficients[count] = quotient;
        count += 1;
        if (remainder == 0) break;
        numerator = denominator;
        denominator = remainder;
    }
    const bytes = count * 8;
    if (bytes > capacity or output == null) return -2;
    for (0..count) |index| {
        const bits: u64 = @bitCast(coefficients[index]);
        for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(bytes);
}
