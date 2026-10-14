/// Count the primes through limit using the Sieve of Eratosthenes.
export fn sieve_of_eratosthenes(limit: i64) i64 {
    if (limit < 0 or limit > 4096) return -1;
    if (limit < 2) return 0;
    var prime: [4097]bool = @splat(false);
    for (2..@as(usize, @intCast(limit)) + 1) |value| prime[value] = true;
    var factor: usize = 2;
    while (factor <= @as(usize, @intCast(limit)) / factor) : (factor += 1) {
        if (prime[factor]) {
            var multiple = factor * factor;
            while (multiple <= @as(usize, @intCast(limit))) : (multiple += factor) {
                prime[multiple] = false;
            }
        }
    }
    var count: i64 = 0;
    for (2..@as(usize, @intCast(limit)) + 1) |value| {
        if (prime[value]) count += 1;
    }
    return count;
}
