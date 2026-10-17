const MAX_PRIMES: usize = 100;

var prime_cache: [MAX_PRIMES]i32 = [_]i32{0} ** MAX_PRIMES;
var prime_count: usize = 0;
var next_candidate: i32 = 3;

fn isPrimeCandidate(candidate: i32) bool {
    for (prime_cache[0..prime_count]) |divisor| {
        if (divisor > @divTrunc(candidate, divisor)) break;
        if (@mod(candidate, divisor) == 0) return false;
    }
    return true;
}

fn extendPrimeCache(requested_count: usize) void {
    if (prime_count == 0) {
        prime_cache[0] = 2;
        prime_count = 1;
    }
    while (prime_count < requested_count) {
        const candidate = next_candidate;
        next_candidate += 1;
        if (isPrimeCandidate(candidate)) {
            prime_cache[prime_count] = candidate;
            prime_count += 1;
        }
    }
}

export fn stream_sieve(number_of_primes: i64, output: ?[*]u8, output_capacity: usize) i64 {
    if (number_of_primes < -2147483648 or number_of_primes > 100) return -1;
    if (number_of_primes <= 0) return 0;
    const count: usize = @intCast(number_of_primes);
    const required = count * 4;
    if (output == null or output_capacity < required) return -2;
    const output_ptr = output.?;

    extendPrimeCache(count);
    for (0..count) |index| {
        const bits: u32 = @intCast(prime_cache[index]);
        for (0..4) |byte| output_ptr[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(required);
}
