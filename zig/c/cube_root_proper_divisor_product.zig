const MAX_INPUT_LENGTH: usize = 2;
const MAX_VALUE: usize = 600_000;
const MAX_K: i64 = 50_000;

fn buildPrimePrefix(prefix: []u32) void {
    prefix[0] = 0;
    prefix[1] = 0;
    for (2..MAX_VALUE + 1) |value| prefix[value] = 1;
    var prime: usize = 2;
    while (prime <= MAX_VALUE / prime) : (prime += 1) {
        if (prefix[prime] != 0) {
            var multiple = prime * prime;
            while (multiple <= MAX_VALUE) : (multiple += prime) prefix[multiple] = 0;
        }
    }
    for (1..MAX_VALUE + 1) |value| prefix[value] += prefix[value - 1];
}

fn isPrime(value: usize, prefix: []const u32) bool {
    return value >= 2 and prefix[value] - prefix[value - 1] == 1;
}

fn countTauEight(limit: usize, prefix: []const u32) i64 {
    var count: i64 = 0;
    var prime: u64 = 2;
    while (true) : (prime += 1) {
        var power: u64 = 1;
        for (0..7) |_| {
            if (power > limit / prime) { power = limit + 1; break; }
            power *= prime;
        }
        if (power > limit) break;
        if (isPrime(@intCast(prime), prefix)) count += 1;
    }
    prime = 2;
    while (true) : (prime += 1) {
        const cube = prime * prime * prime;
        if (cube > limit) break;
        if (isPrime(@intCast(prime), prefix)) {
            const q_max: usize = @intCast(limit / cube);
            count += prefix[q_max];
            if (prime <= q_max) count -= 1;
        }
    }
    prime = 2;
    while (prime * prime * prime < limit) : (prime += 1) {
        if (!isPrime(@intCast(prime), prefix)) continue;
        var other = prime + 1;
        while (true) : (other += 1) {
            if (prime > limit / other) break;
            const product = prime * other;
            const last_prime: usize = @intCast(limit / product);
            if (last_prime <= other) break;
            if (isPrime(@intCast(other), prefix))
                count += prefix[last_prime] - prefix[@intCast(other)];
        }
    }
    return count;
}

fn sequenceTerm(k: i64) i64 {
    if (k == 1) return 1;
    var prefix: [MAX_VALUE + 1]u32 = @splat(0);
    buildPrimePrefix(&prefix);
    const target = k - 1;
    if (countTauEight(MAX_VALUE, &prefix) < target) return -1;
    var low: usize = 1;
    var high: usize = MAX_VALUE;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (countTauEight(middle, &prefix) >= target) high = middle else low = middle + 1;
    }
    return @intCast(low);
}

export fn cube_root_proper_divisor_product(
    input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 1 or input[0] > MAX_K) return -1;
    return sequenceTerm(input[0]);
}
