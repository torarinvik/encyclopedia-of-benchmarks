const MAX_PRIMES: usize = 1000;
const TARGET_SIZE: usize = 5;
const PAIR_CACHE_SIZE: usize = MAX_PRIMES * MAX_PRIMES;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    if (value == 2 or value == 3) return true;
    if (@mod(value, 2) == 0 or @mod(value, 3) == 0) return false;
    var divisor: i64 = 5;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 6) {
        if (@mod(value, divisor) == 0 or @mod(value, divisor + 2) == 0) return false;
    }
    return true;
}

fn concatenate(left: i64, right: i64) i64 {
    var scale: i64 = 10;
    while (scale <= right) : (scale *= 10) {}
    return left * scale + right;
}

fn pairWorks(primes: *const [MAX_PRIMES]i64, cache: *[PAIR_CACHE_SIZE]u8,
             left_index: usize, right_index: usize) bool {
    const key = left_index * MAX_PRIMES + right_index;
    if (cache[key] != 0) return cache[key] == 2;
    const reverse_key = right_index * MAX_PRIMES + left_index;
    if (cache[reverse_key] != 0) return cache[reverse_key] == 2;
    const left = primes[left_index];
    const right = primes[right_index];
    const result = isPrime(concatenate(left, right)) and isPrime(concatenate(right, left));
    const state: u8 = if (result) 2 else 1;
    cache[key] = state;
    cache[reverse_key] = state;
    return result;
}

fn searchSet(primes: *const [MAX_PRIMES]i64, prime_count: usize,
             cache: *[PAIR_CACHE_SIZE]u8, chain: *[TARGET_SIZE]usize,
             depth: usize, start: usize, sum: i64) i64 {
    if (depth == TARGET_SIZE) return sum;
    var candidate = start;
    while (candidate < prime_count) : (candidate += 1) {
        var compatible = true;
        for (0..depth) |member| {
            if (!pairWorks(primes, cache, candidate, chain[member])) {
                compatible = false;
                break;
            }
        }
        if (!compatible) continue;
        chain[depth] = candidate;
        const result = searchSet(primes, prime_count, cache, chain, depth + 1,
                                 candidate + 1, sum + primes[candidate]);
        if (result != 0) return result;
    }
    return 0;
}

pub export fn problem60(placeholder: i64) i64 {
    if (placeholder != 0) return -1;
    var primes = [_]i64{0} ** MAX_PRIMES;
    primes[0] = 3;
    primes[1] = 7;
    primes[2] = 13;
    primes[3] = 19;
    var prime_count: usize = 4;
    while (prime_count < MAX_PRIMES) : (prime_count += 1) {
        var candidate = primes[prime_count - 1] + 3;
        while (!isPrime(candidate)) : (candidate += 3) {}
        primes[prime_count] = candidate;
    }
    var cache = [_]u8{0} ** PAIR_CACHE_SIZE;
    var chain = [_]usize{0} ** TARGET_SIZE;
    for (0..prime_count) |start| {
        chain[0] = start;
        const result = searchSet(&primes, prime_count, &cache, &chain, 1,
                                 start + 1, primes[start]);
        if (result != 0) return result;
    }
    return -1;
}
