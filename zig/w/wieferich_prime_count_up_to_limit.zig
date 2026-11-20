const MAX_LIMIT: i64 = 5000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn modularPower(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn countWieferich(limit: usize) i64 {
    var prime: [5001]u8 = @splat(0);
    for (0..limit + 1) |n| prime[n] = 1;
    prime[0] = 0;
    prime[1] = 0;
    var divisor: usize = 2;
    while (divisor * divisor <= limit) : (divisor += 1) {
        if (prime[divisor] == 0) continue;
        var multiple = divisor * divisor;
        while (multiple <= limit) : (multiple += divisor) prime[multiple] = 0;
    }
    var count: i64 = 0;
    var p: usize = 3;
    while (p <= limit) : (p += 2) {
        if (prime[p] != 0) {
            const p64: i64 = @intCast(p);
            if (modularPower(2, p64 - 1, p64 * p64) == 1) count += 1;
        }
    }
    return count;
}

export fn wieferich_prime_count_up_to_limit(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 or input[0] < 2 or input[0] > MAX_LIMIT) return -1;
    return countWieferich(@intCast(input[0]));
}
