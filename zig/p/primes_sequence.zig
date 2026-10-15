/// Generate zero-based prime terms using divisibility by all earlier primes.
export fn primes_sequence(index: i64) i64 {
    if (index < 0 or index > 99) return -1;
    var primes: [100]i64 = undefined;
    @memset(&primes, 0);
    primes[0] = 2;
    var count: usize = 1;
    var candidate: i64 = 3;
    while (count <= @as(usize, @intCast(index))) {
        var is_prime = true;
        for (0..count) |i| {
            if (@rem(candidate, primes[i]) == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) {
            primes[count] = candidate;
            count += 1;
        }
        candidate += 2;
    }
    return primes[@intCast(index)];
}
