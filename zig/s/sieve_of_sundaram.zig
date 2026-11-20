/// Count primes through limit with Sundaram's index sieve.
export fn sieve_of_sundaram(limit: i64) i64 {
    if (limit < 0 or limit > 4096) return -1;
    if (limit < 2) return 0;

    const max_index: usize = @intCast(@divTrunc(limit - 1, 2));
    var composite: [2048]bool = @splat(false);
    var i: usize = 1;
    while (2 * i * (i + 1) <= max_index) : (i += 1) {
        var j = i;
        while (true) : (j += 1) {
            const index = i + j + 2 * i * j;
            if (index > max_index) break;
            composite[index] = true;
        }
    }

    var count: i64 = 1;
    for (1..max_index + 1) |index| {
        if (!composite[index]) count += 1;
    }
    return count;
}
