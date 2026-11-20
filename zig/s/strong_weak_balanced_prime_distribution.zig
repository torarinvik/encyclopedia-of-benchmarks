const MAX_LIMIT: i64 = 100_000;

fn count(limit: i64) i64 {
    var prime: [200001]bool = @splat(true);
    const ceiling = 2 * limit;
    prime[0] = false;
    prime[1] = false;
    var divisor: i64 = 2;
    while (divisor * divisor <= ceiling) : (divisor += 1) {
        if (!prime[@intCast(divisor)]) continue;
        var multiple = divisor * divisor;
        while (multiple <= ceiling) : (multiple += divisor) {
            prime[@intCast(multiple)] = false;
        }
    }

    var strong: i64 = 0;
    var weak: i64 = 0;
    var balanced: i64 = 0;
    var previous: i64 = 0;
    var current: i64 = 0;
    var candidate: i64 = 2;
    while (candidate <= ceiling) : (candidate += 1) {
        if (!prime[@intCast(candidate)]) continue;
        if (previous != 0 and current >= 3 and current <= limit) {
            const twice = 2 * current;
            const neighbors = previous + candidate;
            if (twice > neighbors) strong += 1
            else if (twice < neighbors) weak += 1
            else balanced += 1;
        }
        previous = current;
        current = candidate;
    }
    return strong * 10_000_000_000 + weak * 100_000 + balanced;
}

export fn strong_weak_balanced_prime_distribution(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 2) return -1;
    const limit = input.?[0];
    if (length != 1 or limit < 3 or limit > MAX_LIMIT) return -1;
    return count(limit);
}
