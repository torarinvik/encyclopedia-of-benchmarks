const PRIME_LIMIT: usize = 10_000;

fn digitSignature(value: i64) usize {
    var digits = [4]i64{ @divTrunc(value, 1000), @mod(@divTrunc(value, 100), 10), @mod(@divTrunc(value, 10), 10), @mod(value, 10) };
    for (0..4) |first| {
        for (first + 1..4) |second| {
            if (digits[first] > digits[second]) {
                const temporary = digits[first];
                digits[first] = digits[second];
                digits[second] = temporary;
            }
        }
    }
    return @intCast(digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3]);
}

pub export fn problem49(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var prime_flags: [PRIME_LIMIT]bool = @splat(false);
    for (2..PRIME_LIMIT) |value| {
        prime_flags[value] = true;
    }
    var prime: usize = 2;
    while (prime * prime < PRIME_LIMIT) : (prime += 1) {
        if (!prime_flags[prime]) continue;
        var multiple = prime * prime;
        while (multiple < PRIME_LIMIT) : (multiple += prime) {
            prime_flags[multiple] = false;
        }
    }
    var primes: [1100]i64 = @splat(0);
    var signatures: [PRIME_LIMIT]usize = @splat(0);
    var prime_count: usize = 0;
    var value: usize = 1001;
    while (value < PRIME_LIMIT) : (value += 2) {
        if (prime_flags[value]) {
            primes[prime_count] = @intCast(value);
            prime_count += 1;
            signatures[value] = digitSignature(@intCast(value));
        }
    }
    var seen_signatures: [PRIME_LIMIT]bool = @splat(false);
    var best: i64 = 0;
    for (0..prime_count) |seed| {
        const signature = signatures[@intCast(primes[seed])];
        if (seen_signatures[signature]) continue;
        seen_signatures[signature] = true;
        var group: [24]i64 = @splat(0);
        var group_count: usize = 0;
        for (0..prime_count) |candidate| {
            const candidate_value = primes[candidate];
            if (signatures[@intCast(candidate_value)] == signature) {
                group[group_count] = candidate_value;
                group_count += 1;
            }
        }
        var found = false;
        var first: usize = 0;
        while (first < group_count and !found) : (first += 1) {
            var second = first + 1;
            while (second < group_count and !found) : (second += 1) {
                var third = second + 1;
                while (third < group_count) : (third += 1) {
                    if (group[second] - group[first] == group[third] - group[second]) {
                        const sequence = group[first] * 100_000_000 + group[second] * 10_000 + group[third];
                        if (sequence > best) best = sequence;
                        found = true;
                        break;
                    }
                }
            }
        }
    }
    return best;
}
