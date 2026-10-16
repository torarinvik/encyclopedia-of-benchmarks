const MAX_N: i64 = 10_000_000_000;

fn isPrime(value: i64, primes: []const i64) bool {
    for (primes) |p| { if (@rem(value, p) == 0) return false; }
    return true;
}

export fn problem111(n: i64) i64 {
    if (n < 1000 or n > MAX_N) return -1;
    var composite = [_]bool{false} ** 100_002;
    var primes = [_]i64{0} ** 100_001;
    var prime_count: usize = 0;
    var root: i64 = 0; while (root + 1 <= @divTrunc(n, root + 1)) : (root += 1) {}
    const sieve_limit: usize = @intCast(root + 1);
    for (2..(sieve_limit + 1)) |p| {
        if (composite[p]) continue;
        primes[prime_count] = @intCast(p); prime_count += 1;
        if (p * p <= sieve_limit) { var multiple = p * p; while (multiple <= sieve_limit) : (multiple += p) composite[multiple] = true; }
    }
    var digits: usize = 0; var copy = n; while (copy > 0) : (copy = @divTrunc(copy, 10)) digits += 1;
    const width: usize = digits - 1; const repeated_two = width - 2; const prime_slice = primes[0..prime_count];
    var total: i64 = 0;
    for (1..10) |i| for (1..10) |j| {
        var value: i64 = @intCast(i); for (0..(width - 2)) |_| value *= 10; value = value * 10 + @as(i64, @intCast(j));
        if (isPrime(value, prime_slice)) total += value;
    };
    var one_digit = [_]bool{false} ** 10;
    for (1..10) |i| for (0..width) |j| for (0..10) |k| {
        var value: i64 = 0; for (0..width) |pos| value = value * 10 + @as(i64, @intCast(if (pos == j) k else i));
        if (isPrime(value, prime_slice)) { one_digit[i] = true; total += value; }
    };
    for (1..10) |i| {
        if (one_digit[i]) continue;
        for (0..(repeated_two + 1)) |j| for (0..(repeated_two - j + 1)) |k| for (0..10) |m1| {
            if (m1 == 0 and j == 0) continue;
            for (0..10) |m2| {
                var value: i64 = 0;
                for (0..width) |pos| { const digit = if (pos == j) m1 else if (pos == j + k + 1) m2 else i; value = value * 10 + @as(i64, @intCast(digit)); }
                if (isPrime(value, prime_slice)) total += value;
            }
        };
    }
    return total;
}
