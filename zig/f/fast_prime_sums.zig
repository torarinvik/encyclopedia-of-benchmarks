const SIEVE_LIMIT: usize = 32_000;
const SIEVE_LIMIT_I64: i64 = 32_000;
const PRIME_CAPACITY: usize = 3_500;
const PHI_ROWS: usize = 12;
const PHI_COLUMNS: usize = 30_000;
const PHI_COLUMNS_I64: i64 = 30_000;
const MAX_INPUT: i64 = 1_000_000_000;

const Context = struct {
    composite: [SIEVE_LIMIT + 1]bool = [_]bool{false} ** (SIEVE_LIMIT + 1),
    primes: [PRIME_CAPACITY]i64 = [_]i64{0} ** PRIME_CAPACITY,
    prime_count: [SIEVE_LIMIT + 1]usize = [_]usize{0} ** (SIEVE_LIMIT + 1),
    prime_sum: [SIEVE_LIMIT + 1]i64 = [_]i64{0} ** (SIEVE_LIMIT + 1),
    phi: [PHI_ROWS * PHI_COLUMNS]i64 = [_]i64{0} ** (PHI_ROWS * PHI_COLUMNS),
};

fn sqrtFloor(n: i64) i64 {
    var low: i64 = 0;
    var high = n + 1;
    while (low + 1 < high) {
        const middle = low + (high - low) / 2;
        if (middle <= n / middle) low = middle else high = middle;
    }
    return low;
}

fn cbrtFloor(n: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 1;
    while (high * high * high <= n) high *= 2;
    while (low + 1 < high) {
        const middle = low + (high - low) / 2;
        if (middle * middle * middle <= n) low = middle else high = middle;
    }
    return low;
}

fn weightedPhi(context: *Context, n: i64, count: usize) i64 {
    if (n <= 0) return 0;
    if (count == 0) return n * (n + 1) / 2;
    const prime = context.primes[count - 1];
    if (n <= prime) return 1;
    if (count < PHI_ROWS and n < PHI_COLUMNS_I64)
        return context.phi[count * PHI_COLUMNS + @as(usize, @intCast(n))];
    if (n < SIEVE_LIMIT_I64 and prime * prime >= n)
        return context.prime_sum[@intCast(n)] - context.prime_sum[@intCast(prime)] + 1;
    if (n < SIEVE_LIMIT_I64 and prime * prime * prime >= n) {
        var result = context.prime_sum[@intCast(n)] - context.prime_sum[@intCast(prime)] + 1;
        const limit = context.prime_count[@intCast(sqrtFloor(n))];
        var index = count;
        while (index < limit) : (index += 1) {
            const other = context.primes[index];
            result += other * (context.prime_sum[@intCast(n / other)] - context.prime_sum[@intCast(other - 1)]);
        }
        return result;
    }
    return weightedPhi(context, n, count - 1) - prime * weightedPhi(context, n / prime, count - 1);
}

fn sumPrimes(context: *Context, n: i64) i64 {
    if (n <= SIEVE_LIMIT_I64) return context.prime_sum[@intCast(n)];
    const cube = @as(usize, @intCast(cbrtFloor(n)));
    const square = @as(usize, @intCast(sqrtFloor(n)));
    const first = context.prime_count[cube];
    const last = context.prime_count[square];
    var result = weightedPhi(context, n, first) + context.prime_sum[cube] - 1;
    var index = first;
    while (index < last) : (index += 1) {
        const prime = context.primes[index];
        const quotient = n / prime;
        result -= (sumPrimes(context, quotient) - context.prime_sum[@intCast(prime - 1)]) * prime;
    }
    return result;
}

export fn fast_prime_sums(value: i64) i64 {
    if (value < 0 or value > MAX_INPUT) return -1;
    var context = Context{};
    var candidate: usize = 2;
    while (candidate * candidate <= SIEVE_LIMIT) : (candidate += 1) {
        if (context.composite[candidate]) continue;
        var multiple = candidate * candidate;
        while (multiple <= SIEVE_LIMIT) : (multiple += candidate) {
            context.composite[multiple] = true;
        }
    }
    var count: usize = 0;
    for (2..SIEVE_LIMIT + 1) |n| {
        if (!context.composite[n]) {
            context.primes[count] = @intCast(n);
            count += 1;
        }
        const count_increment: usize = if (context.composite[n]) 0 else 1;
        context.prime_count[n] = context.prime_count[n - 1] + count_increment;
        const sum_increment: i64 = if (context.composite[n]) 0 else @intCast(n);
        context.prime_sum[n] = context.prime_sum[n - 1] + sum_increment;
    }
    for (0..PHI_COLUMNS) |n| context.phi[n] = @as(i64, @intCast(n)) * @as(i64, @intCast(n + 1)) / 2;
    for (1..PHI_ROWS) |row| {
        const prime = context.primes[row - 1];
        const previous = (row - 1) * PHI_COLUMNS;
        const current = row * PHI_COLUMNS;
        for (0..PHI_COLUMNS) |n|
            context.phi[current + n] = context.phi[previous + n] - prime * context.phi[previous + n / @as(usize, @intCast(prime))];
    }
    return sumPrimes(&context, value);
}
