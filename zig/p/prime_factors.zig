fn decimalLength(valueInput: i64) usize {
    var value = valueInput;
    var length: usize = 1;
    while (value >= 10) : (length += 1) { value = @divTrunc(value, 10); }
    return length;
}

fn requiredLength(value: i64) usize {
    var length: usize = 0;
    var count: usize = 0;
    var remaining = value;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(remaining, divisor)) : (divisor += 1) {
        while (@mod(remaining, divisor) == 0) {
            length += decimalLength(divisor);
            if (count > 0) length += 1;
            count += 1;
            remaining = @divTrunc(remaining, divisor);
        }
    }
    if (remaining > 1) {
        length += decimalLength(remaining);
        if (count > 0) length += 1;
    }
    return length;
}

fn appendDecimal(valueInput: i64, output: [*]u8, positionInput: usize) usize {
    var value = valueInput;
    var digits: [10]u8 = undefined;
    var count: usize = 0;
    while (value > 0) : (count += 1) {
        digits[count] = @intCast(@mod(value, 10));
        value = @divTrunc(value, 10);
    }
    var position = positionInput;
    while (count > 0) {
        count -= 1;
        output[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

/// Encode prime factors in ascending order, retaining multiplicity.
export fn prime_factors(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > 2147483647) return -1;
    const required = requiredLength(value);
    if (output_capacity < required) return -2;
    var position: usize = 0;
    var count: usize = 0;
    var remaining = value;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(remaining, divisor)) : (divisor += 1) {
        while (@mod(remaining, divisor) == 0) {
            if (count > 0) {
                output[position] = ',';
                position += 1;
            }
            position = appendDecimal(divisor, output, position);
            count += 1;
            remaining = @divTrunc(remaining, divisor);
        }
    }
    if (remaining > 1) {
        if (count > 0) {
            output[position] = ',';
            position += 1;
        }
        position = appendDecimal(remaining, output, position);
    }
    return @intCast(position);
}
