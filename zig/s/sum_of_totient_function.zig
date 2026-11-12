const MAX_N: i64 = 1_000_000_000;
const BASE_LIMIT: usize = 100_000;
const MAX_CACHE: usize = 10_002;
const MODULUS: i64 = 998_244_353;

fn triangular_mod(n: i64) i64 {
    var left = n;
    var right = n + 1;
    if (@rem(left, 2) == 0) left = @divTrunc(left, 2) else right = @divTrunc(right, 2);
    return @rem(left, MODULUS) * @rem(right, MODULUS) % MODULUS;
}

fn summatory_phi(value: i64, total_n: i64, prefix: []const i64,
    memo: []i64, visited: []bool) i64 {
    if (value <= BASE_LIMIT) return prefix[@intCast(value)];
    const cache_index: usize = @intCast(@divTrunc(total_n, value));
    if (visited[cache_index]) return memo[cache_index];
    var answer = triangular_mod(value);
    var left: i64 = 2;
    while (left <= value) {
        const quotient = @divTrunc(value, left);
        const right = @divTrunc(value, quotient);
        const block_size = right - left + 1;
        const sub_sum = summatory_phi(quotient, total_n, prefix, memo, visited);
        const contribution = @rem(block_size, MODULUS) * sub_sum % MODULUS;
        answer = @rem(answer - contribution + MODULUS, MODULUS);
        left = right + 1;
    }
    visited[cache_index] = true;
    memo[cache_index] = answer;
    return answer;
}

export fn sum_of_totient_function(n: i64) i64 {
    if (n < 1 or n > MAX_N) return -1;
    var prefix: [BASE_LIMIT + 1]i64 = @splat(0);
    for (0..(BASE_LIMIT + 1)) |value| prefix[value] = @intCast(value);
    const sieve_limit: usize = @intCast(@min(n, @as(i64, @intCast(BASE_LIMIT))));
    for (2..(sieve_limit + 1)) |prime| {
        if (prefix[prime] != @as(i64, @intCast(prime))) continue;
        var multiple = prime;
        while (multiple <= sieve_limit) : (multiple += prime) {
            prefix[multiple] -= @divTrunc(prefix[multiple], @as(i64, @intCast(prime)));
        }
    }
    var running: i64 = 0;
    for (1..(sieve_limit + 1)) |value| {
        running = @rem(running + prefix[value], MODULUS);
        prefix[value] = running;
    }
    if (n <= @as(i64, @intCast(BASE_LIMIT))) return prefix[@intCast(n)];

    var memo: [MAX_CACHE]i64 = @splat(0);
    var visited: [MAX_CACHE]bool = @splat(false);
    return summatory_phi(n, n, prefix[0..], memo[0..], visited[0..]);
}
