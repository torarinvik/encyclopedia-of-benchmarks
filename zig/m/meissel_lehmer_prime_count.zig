const MAX_INPUT: i64 = 100_000_000;
const SIEVE_LIMIT: usize = 10_000;
const MAX_PRIMES: usize = 1_300;
const PHI_CACHE_X: usize = 2_048;
const PHI_CACHE_S: usize = 32;

const Context = struct {
    composite: [SIEVE_LIMIT + 1]bool = [_]bool{false} ** (SIEVE_LIMIT + 1),
    primes: [MAX_PRIMES]i32 = [_]i32{0} ** MAX_PRIMES,
    prime_count_prefix: [SIEVE_LIMIT + 1]i32 = [_]i32{0} ** (SIEVE_LIMIT + 1),
    phi_cache: [PHI_CACHE_S + 1][PHI_CACHE_X + 1]i32 = [_][PHI_CACHE_X + 1]i32{[_]i32{0} ** (PHI_CACHE_X + 1)} ** (PHI_CACHE_S + 1),
};

fn integerSqrt(value: u64) u64 {
    var low: u64 = 0;
    var high = value + 1;
    while (low + 1 < high) {
        const middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            low = middle;
        } else {
            high = middle;
        }
    }
    return low;
}

fn integerCubeRoot(value: u64) u64 {
    var low: u64 = 0;
    var high = value + 1;
    while (low + 1 < high) {
        const middle = low + (high - low) / 2;
        if (middle <= value / middle / middle) {
            low = middle;
        } else {
            high = middle;
        }
    }
    return low;
}

fn phi(context: *Context, value: u64, prime_count: usize) i64 {
    if (value == 0) return 0;
    if (prime_count == 0) return @intCast(value);
    if (prime_count == 1) return @intCast(value - value / 2);
    const prime: u64 = @intCast(context.primes[prime_count - 1]);
    if (value < prime) return 1;
    if (value <= PHI_CACHE_X and prime_count <= PHI_CACHE_S) {
        const x: usize = @intCast(value);
        const cached = context.phi_cache[prime_count][x];
        if (cached != 0) return cached;
        const result = phi(context, value, prime_count - 1) - phi(context, value / prime, prime_count - 1);
        context.phi_cache[prime_count][x] = @intCast(result);
        return result;
    }
    return phi(context, value, prime_count - 1) - phi(context, value / prime, prime_count - 1);
}

fn lehmerCount(context: *Context, value: u64) i64 {
    if (value <= SIEVE_LIMIT) return context.prime_count_prefix[@intCast(value)];
    const a: usize = @intCast(context.prime_count_prefix[@intCast(integerSqrt(integerSqrt(value)))]);
    const b: usize = @intCast(context.prime_count_prefix[@intCast(integerSqrt(value))]);
    const c: usize = @intCast(context.prime_count_prefix[@intCast(integerCubeRoot(value))]);
    var result = phi(context, value, a) + @as(i64, @intCast((b + a - 2) * (b - a + 1) / 2));
    for (a..b) |i| {
        const quotient = value / @as(u64, @intCast(context.primes[i]));
        result -= lehmerCount(context, quotient);
        if (i < c) {
            const limit: usize = @intCast(lehmerCount(context, integerSqrt(quotient)));
            for (i..limit) |j| {
                result -= lehmerCount(context, quotient / @as(u64, @intCast(context.primes[j]))) - @as(i64, @intCast(j));
            }
        }
    }
    return result;
}

export fn meissel_lehmer_prime_count(value: i64) i64 {
    if (value < 0 or value > MAX_INPUT) return -1;
    var context = Context{};
    for (2..SIEVE_LIMIT + 1) |candidate| {
        if (context.composite[candidate]) continue;
        if (candidate <= SIEVE_LIMIT / candidate) {
            var multiple = candidate * candidate;
            while (multiple <= SIEVE_LIMIT) : (multiple += candidate) {
                context.composite[multiple] = true;
            }
        }
    }
    var prime_count: usize = 0;
    for (2..SIEVE_LIMIT + 1) |candidate| {
        if (!context.composite[candidate]) {
            context.primes[prime_count] = @intCast(candidate);
            prime_count += 1;
        }
        const prime_increment: i32 = if (context.composite[candidate]) 0 else 1;
        context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1] + prime_increment;
    }
    return lehmerCount(&context, @intCast(value));
}
