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

fn requiredLength(number_of_primes: i64) usize {
    var length: usize = 0;
    var count: i64 = 0;
    var value: i64 = 2;
    while (count < number_of_primes) : (value += 1) {
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

/// Encode the first n primes in ascending order as comma-separated decimal bytes.
export fn first_n_primes(number_of_primes: i64, output: [*]u8, output_capacity: usize) i64 {
    if (number_of_primes < 0 or number_of_primes > 20) return -1;
    const required = requiredLength(number_of_primes);
    if (output_capacity < required) return -2;
    var position: usize = 0;
    var count: i64 = 0;
    var value: i64 = 2;
    while (count < number_of_primes) : (value += 1) {
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
