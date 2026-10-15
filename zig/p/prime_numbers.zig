fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

fn decimalLength(valueInput: i64) usize {
    var value = valueInput;
    var length: usize = 1;
    while (value >= 10) : (length += 1) { value = @divTrunc(value, 10); }
    return length;
}

fn requiredLength(limit: i64) usize {
    var length: usize = 0;
    var count: usize = 0;
    var value: i64 = 2;
    while (value <= limit) : (value += 1) {
        if (isPrime(value)) {
            length += decimalLength(value);
            if (count > 0) length += 1;
            count += 1;
        }
    }
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

/// Encode all primes through an inclusive limit as comma-separated decimal bytes.
export fn prime_numbers(limit: i64, output: [*]u8, output_capacity: usize) i64 {
    if (limit < 0 or limit > 80) return -1;
    const required = requiredLength(limit);
    if (output_capacity < required) return -2;
    var position: usize = 0;
    var count: usize = 0;
    var value: i64 = 2;
    while (value <= limit) : (value += 1) {
        if (isPrime(value)) {
            if (count > 0) {
                output[position] = ',';
                position += 1;
            }
            position = appendDecimal(value, output, position);
            count += 1;
        }
    }
    return @intCast(position);
}
