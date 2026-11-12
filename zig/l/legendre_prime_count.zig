const MAX_INPUT: i64 = 10_000;

fn legendrePhi(primes: []const i64, value: i64, count: usize) i64 {
    if (value == 0) return 0;
    if (count == 0) return value;
    if (count == 1) return value - @divTrunc(value, 2);
    const prime = primes[count - 1];
    if (value < prime) return 1;
    return legendrePhi(primes, value, count - 1) -
        legendrePhi(primes, @divTrunc(value, prime), count - 1);
}

export fn legendre_prime_count(value: i64) i64 {
    if (value < 0 or value > MAX_INPUT) return -1;
    if (value < 2) return 0;
    var root: i64 = 0;
    while ((root + 1) * (root + 1) <= value) : (root += 1) {}
    var composite = [_]bool{false} ** 101;
    var candidate: i64 = 2;
    while (candidate * candidate <= root) : (candidate += 1) {
        if (!composite[@intCast(candidate)]) {
            var multiple = candidate * candidate;
            while (multiple <= root) : (multiple += candidate)
                composite[@intCast(multiple)] = true;
        }
    }
    var primes: [25]i64 = undefined;
    var count: usize = 0;
    candidate = 2;
    while (candidate <= root) : (candidate += 1) {
        if (!composite[@intCast(candidate)]) {
            primes[count] = candidate;
            count += 1;
        }
    }
    return legendrePhi(primes[0..count], value, count) + @as(i64, @intCast(count)) - 1;
}
