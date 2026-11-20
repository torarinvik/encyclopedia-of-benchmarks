const MAX_N: i64 = 1_000_000;
const MAX_ROOT: usize = 1_000;
const MAX_PRIMES: usize = 168;

const State = struct {
    n: i64,
    total: i64,
    prime_count: usize = 0,
    primes: [MAX_PRIMES]i64 = @splat(0),
};

fn enumeratePowerful(state: *State, start: usize, current: i64, current_h: i64) void {
    const remaining = @divTrunc(state.n, current);
    var prime_index = start;
    while (prime_index < state.prime_count) : (prime_index += 1) {
        const prime = state.primes[prime_index];
        if (prime > @divTrunc(remaining, prime)) break;
        var prime_power = prime * prime;
        var h_power = prime - 1;
        while (prime_power <= remaining) {
            const powerful = current * prime_power;
            const h_value = current_h * h_power;
            state.total += h_value * @divTrunc(state.n, powerful);
            enumeratePowerful(state, prime_index + 1, powerful, h_value);
            if (prime_power > @divTrunc(remaining, prime)) break;
            prime_power *= prime;
            h_power *= prime;
        }
    }
}

fn solve(n: i64) i64 {
    var root: i64 = 1;
    while (root + 1 <= @divTrunc(n, root + 1)) root += 1;

    var composite: [MAX_ROOT + 1]bool = @splat(false);
    var state = State{ .n = n, .total = n };
    var candidate: usize = 2;
    while (candidate <= @as(usize, @intCast(root))) : (candidate += 1) {
        if (composite[candidate]) continue;
        state.primes[state.prime_count] = @intCast(candidate);
        state.prime_count += 1;
        if (candidate <= @as(usize, @intCast(root)) / candidate) {
            var multiple = candidate * candidate;
            while (multiple <= @as(usize, @intCast(root))) : (multiple += candidate) {
                composite[multiple] = true;
            }
        }
    }
    enumeratePowerful(&state, 0, 1, 1);
    return state.total;
}

export fn powerful_number_summatory_sieve(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const n = input[0];
    if (n < 1 or n > MAX_N) return -1;
    return solve(n);
}
