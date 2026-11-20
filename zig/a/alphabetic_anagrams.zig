const MAX_LENGTH: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = 10;
const ALPHABET_SIZE: usize = 26;

fn factorial(value: i64) i64 {
    var result: i64 = 1;
    var factor: i64 = 2;
    while (factor <= value) : (factor += 1) result *= factor;
    return result;
}

fn solve(input: []const i64) i64 {
    if (input.len < 1 or input.len > MAX_PARSEABLE_LENGTH) return -1;
    const n_raw = input[0];
    if (n_raw < 0 or n_raw > MAX_LENGTH) return -1;
    const n: usize = @intCast(n_raw);
    if (input.len != n + 1) return -1;
    var frequency: [ALPHABET_SIZE]i64 = @splat(0);
    for (input[1..]) |symbol| {
        if (symbol < 0 or symbol > 25) return -1;
        frequency[@intCast(symbol)] += 1;
    }
    var denominator: i64 = 1;
    for (frequency) |count| denominator *= factorial(count);
    var ways = factorial(n_raw) / denominator;
    var rank: i64 = 1;
    var remaining = n_raw;
    for (input[1..]) |actual_raw| {
        const actual: usize = @intCast(actual_raw);
        for (0..actual) |smaller| {
            if (frequency[smaller] > 0)
                rank += ways * frequency[smaller] / remaining;
        }
        ways = ways * frequency[actual] / remaining;
        frequency[actual] -= 1;
        remaining -= 1;
    }
    return rank;
}

pub export fn alphabetic_anagrams(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    return solve(input[0..length]);
}
