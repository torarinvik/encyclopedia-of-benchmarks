/// Primes strictly between bounded prime endpoints, encoded as ASCII.
const MAX_PRIME_COUNT: usize = 256;

fn isPrimeCandidate(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn decimalLength(value: i64) usize {
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

fn writeDecimal(output: [*]u8, offset: *usize, value: i64) void {
    var remaining = value;
    if (remaining >= 100) {
        output[offset.*] = @intCast(48 + @divTrunc(remaining, 100));
        offset.* += 1;
        remaining = @rem(remaining, 100);
    }
    if (remaining >= 10) {
        output[offset.*] = @intCast(48 + @divTrunc(remaining, 10));
        offset.* += 1;
        remaining = @rem(remaining, 10);
    }
    output[offset.*] = @intCast(48 + remaining);
    offset.* += 1;
}

export fn get_primes_between(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const p1 = values[0];
    const p2 = values[1];
    if (p1 < 2 or p1 > 997 or p2 < 2 or p2 > 997 or p1 >= p2) return -1;
    if (!isPrimeCandidate(p1) or !isPrimeCandidate(p2)) return -1;

    var primes: [MAX_PRIME_COUNT]i64 = @splat(0);
    var count: usize = 0;
    var candidate = p1 + 1;
    while (candidate < p2) : (candidate += 1) {
        if (isPrimeCandidate(candidate)) {
            primes[count] = candidate;
            count += 1;
        }
    }
    if (count == 0) return -1;

    var required = count - 1;
    for (primes[0..count]) |prime| required += decimalLength(prime);
    if (output == null or output_capacity < required) return -2;

    var written: usize = 0;
    for (primes[0..count], 0..) |prime, index| {
        if (index != 0) {
            output[written] = ',';
            written += 1;
        }
        writeDecimal(output, &written, prime);
    }
    return @intCast(written);
}
