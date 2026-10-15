fn factorPairs(value: i64, primes: *[10]u32, exponents: *[10]u32) usize {
    var count: usize = 0;
    var remaining = value;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(remaining, divisor)) : (divisor += 1) {
        if (@mod(remaining, divisor) == 0) {
            var exponent: u32 = 0;
            while (@mod(remaining, divisor) == 0) {
                remaining = @divTrunc(remaining, divisor);
                exponent += 1;
            }
            primes[count] = @intCast(divisor);
            exponents[count] = exponent;
            count += 1;
        }
    }
    if (remaining > 1) {
        primes[count] = @intCast(remaining);
        exponents[count] = 1;
        count += 1;
    }
    return count;
}

fn writeU32Le(value: u32, output: [*]u8, position: usize) void {
    for (0..4) |byte| output[position + byte] = @truncate(value >> @intCast(8 * byte));
}

/// Encode ascending prime/exponent pairs as little-endian u32 values.
export fn prime_factorization(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > 1_000_005) return -1;
    var primes: [10]u32 = undefined;
    var exponents: [10]u32 = undefined;
    const count = factorPairs(value, &primes, &exponents);
    const required = count * 8;
    if (output_capacity < required) return -2;
    for (0..count) |index| {
        writeU32Le(primes[index], output, 8 * index);
        writeU32Le(exponents[index], output, 8 * index + 4);
    }
    return @intCast(required);
}
