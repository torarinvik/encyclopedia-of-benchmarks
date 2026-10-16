/// Find the first odd prime index whose source remainder exceeds the limit.
const MAX_LIMIT: i64 = 10_000_000_000;
const PRIME_LIMIT: usize = 300_000;

export fn problem123(limit: i64) i64 {
    if (limit > MAX_LIMIT) return -1;
    var composite: [PRIME_LIMIT + 1]bool = @splat(false);
    var factor: usize = 2;
    while (factor * factor <= PRIME_LIMIT) : (factor += 1) {
        if (!composite[factor]) {
            var multiple = factor * factor;
            while (multiple <= PRIME_LIMIT) : (multiple += factor) composite[multiple] = true;
        }
    }
    var n: i64 = 1;
    var skip_next = false;
    for (2..PRIME_LIMIT + 1) |candidate| {
        if (composite[candidate]) continue;
        if (skip_next) { skip_next = false; continue; }
        if (2 * @as(i64, @intCast(candidate)) * n > limit) return n;
        skip_next = true;
        n += 2;
    }
    return -1;
}
