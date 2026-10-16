export fn problem77(threshold: i64) i64 {
    if (threshold < 0 or threshold > 100_000) return -1;
    var partitions = [_]i64{0} ** 100;
    partitions[0] = 1;
    for (2..100) |prime| {
        var is_prime = true;
        var divisor: usize = 2;
        while (divisor * divisor <= prime) : (divisor += 1) {
            if (prime % divisor == 0) { is_prime = false; break; }
        }
        if (is_prime) {
            for (prime..100) |total| partitions[total] += partitions[total - prime];
        }
    }
    for (1..100) |value| { if (partitions[value] > threshold) return @intCast(value); }
    return -1;
}
