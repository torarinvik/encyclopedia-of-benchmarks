const MAX_INDEX: i64 = 999;

export fn prime_pi_sequence(index: i64) i64 {
    if (index < 0 or index > MAX_INDEX) return -1;
    const target = index + 1;
    var primes: [168]i64 = undefined;
    var prime_count: usize = 0;
    if (target >= 2) {
        primes[prime_count] = 2;
        prime_count += 1;
    }
    var candidate: i64 = 3;
    while (candidate <= target) : (candidate += 2) {
        var is_prime = true;
        var i: usize = 0;
        while (i < prime_count and is_prime) : (i += 1) {
            if (@rem(candidate, primes[i]) == 0) is_prime = false;
        }
        if (is_prime) {
            primes[prime_count] = candidate;
            prime_count += 1;
        }
    }
    return @intCast(prime_count);
}
