/// Count primes through limit with the linear (Euler) sieve.
export fn linear_sieve(limit: i64) i64 {
    if (limit < 0 or limit > 4096) return -1;
    if (limit < 2) return 0;
    var state: [4662]i64 = @splat(0);
    for (2..@as(usize, @intCast(limit)) + 1) |value| {
        if (state[value] == 0) {
            state[value] = @intCast(value);
            const count: usize = @intCast(state[4661]);
            state[4097 + count] = @intCast(value);
            state[4661] += 1;
        }
        const count: usize = @intCast(state[4661]);
        for (0..count) |prime_index| {
            const prime = state[4097 + prime_index];
            if (prime > state[value] or prime > @divTrunc(limit, @as(i64, @intCast(value)))) break;
            state[@intCast(@as(i64, @intCast(value)) * prime)] = prime;
        }
    }
    return state[4661];
}
