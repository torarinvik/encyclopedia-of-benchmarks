/// Prime-exponent factorial using binary buckets and balanced powers.
const MAX_N: usize = 20;
const MAX_BUCKETS: usize = 8;

fn exponentInFactorial(prime: i64, n: i64) i64 {
    var exponent: i64 = 0;
    var quotient = n / prime;
    while (quotient > 0) {
        exponent += quotient;
        quotient /= prime;
    }
    return exponent;
}

fn powerBySquaring(base: i64, exponent_value: u32) i64 {
    var result: i64 = 1;
    var factor = base;
    var remaining = exponent_value;
    while (remaining > 0) {
        if ((remaining & 1) != 0) result *= factor;
        remaining >>= 1;
        if (remaining > 0) factor *= factor;
    }
    return result;
}

export fn fast_factorial(n: i64) i64 {
    if (n < 0 or n > @as(i64, @intCast(MAX_N))) return -1;
    if (n < 2) return 1;

    var is_prime: [MAX_N + 1]bool = @splat(false);
    var candidate: usize = 2;
    while (candidate <= @as(usize, @intCast(n))) : (candidate += 1) is_prime[candidate] = true;
    var prime: usize = 2;
    while (prime * prime <= @as(usize, @intCast(n))) : (prime += 1) {
        if (!is_prime[prime]) continue;
        var multiple = prime * prime;
        while (multiple <= @as(usize, @intCast(n))) : (multiple += prime) is_prime[multiple] = false;
    }

    const exponent_of_two = exponentInFactorial(2, n);
    var next_power_of_two: i64 = 1;
    var power_log2: u32 = 0;
    while (next_power_of_two < exponent_of_two) : (power_log2 += 1) next_power_of_two <<= 1;
    const bucket_count: usize = @as(usize, power_log2 + 1);
    var buckets: [MAX_BUCKETS]i64 = @splat(1);

    candidate = 2;
    while (candidate <= @as(usize, @intCast(n))) : (candidate += 1) {
        if (!is_prime[candidate]) continue;
        const exponent_bits: u32 = @intCast(exponentInFactorial(@intCast(candidate), n));
        var bit: usize = 0;
        var mask: u32 = 1;
        while (bit < bucket_count) : (bit += 1) {
            if ((exponent_bits & mask) != 0) buckets[bit] *= @intCast(candidate);
            mask <<= 1;
        }
    }

    var result: i64 = 1;
    var bit: usize = 0;
    var power_exponent: u32 = 1;
    while (bit < bucket_count) : (bit += 1) {
        result *= powerBySquaring(buckets[bit], power_exponent);
        power_exponent <<= 1;
    }
    return result;
}
