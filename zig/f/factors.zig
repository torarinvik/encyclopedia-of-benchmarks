fn decimalLength(valueInput: i64) usize {
    var value = valueInput;
    var length: usize = 1;
    while (value >= 10) : (length += 1) { value = @divTrunc(value, 10); }
    return length;
}

fn appendDecimal(valueInput: i64, output: [*]u8, positionInput: usize) usize {
    var value = valueInput;
    var digits: [3]u8 = undefined;
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

/// List all positive divisors in ascending decimal order.
export fn factors(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > 256) return -1;
    var required: usize = 0;
    var count: usize = 0;
    var divisor: i64 = 1;
    while (divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) {
            required += decimalLength(divisor);
            if (count > 0) required += 1;
            count += 1;
        }
    }
    if (output_capacity < required) return -2;
    var position: usize = 0;
    count = 0;
    divisor = 1;
    while (divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) {
            if (count > 0) {
                output[position] = ',';
                position += 1;
            }
            position = appendDecimal(divisor, output, position);
            count += 1;
        }
    }
    return @intCast(position);
}
