const MAX_LIMIT: i64 = 999966663333;

export fn problem234(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var composite = [_]bool{false} ** 1_000_100;
    var primes = [_]i64{0} ** 80_000;
    var prime_count: usize = 0;
    var root: i64 = 0;
    while (root + 1 <= @divTrunc(limit, root + 1)) : (root += 1) {}
    const sieve_end: usize = @intCast(root + 100);
    for (2..sieve_end) |p| {
        if (composite[p]) continue;
        primes[prime_count] = @intCast(p);
        prime_count += 1;
        if (p * p < sieve_end) {
            var multiple = p * p;
            while (multiple < sieve_end) : (multiple += p) composite[multiple] = true;
        }
    }
    var total: i64 = 0;
    var index: usize = 0;
    var p = primes[index];
    while (p * p <= limit) {
        const q = primes[index + 1];
        const lower = p * p;
        var upper = q * q;
        var current = lower + p;
        while (upper > current and current <= limit) { total += current; current += p; }
        while (upper - q > limit) upper -= q;
        current = upper - q;
        while (current > lower) { total += current; current -= q; }
        current = 0;
        while (upper > current and current <= limit) {
            if (current <= lower) { current += p * q; continue; }
            if (current > limit) break;
            total -= current * 2;
            current += p * q;
        }
        p = q;
        index += 1;
    }
    return total;
}
