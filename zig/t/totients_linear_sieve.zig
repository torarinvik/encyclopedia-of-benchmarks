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

export fn totients_linear_sieve(n: i64, output: [*]u8, output_capacity: usize) i64 {
    if (n < 1 or n > 80) return -1;
    const limit: usize = @intCast(n);
    var phi: [81]i64 = @splat(0);
    var composite: [81]bool = @splat(false);
    var primes: [80]usize = undefined;
    var prime_count: usize = 0;
    phi[1] = 1;
    for (2..limit + 1) |i| {
        if (!composite[i]) {
            primes[prime_count] = i;
            prime_count += 1;
            phi[i] = @as(i64, @intCast(i)) - 1;
        }
        for (primes[0..prime_count]) |p| {
            if (i * p > limit) break;
            composite[i * p] = true;
            if (i % p == 0) {
                phi[i * p] = phi[i] * @as(i64, @intCast(p));
                break;
            }
            phi[i * p] = phi[i] * (@as(i64, @intCast(p)) - 1);
        }
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
