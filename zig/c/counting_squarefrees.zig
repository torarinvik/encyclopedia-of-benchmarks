const MAX_N: i64 = 1_000_000_000_000;
const MAX_ROOT: usize = 1_000_000;

fn integer_sqrt(value: i64) i64 {
    var low: i64 = 1;
    var high: i64 = @intCast(MAX_ROOT);
    while (low < high) {
        const middle = low + @divTrunc(high - low + 1, 2);
        if (middle <= @divTrunc(value, middle)) low = middle else high = middle - 1;
    }
    return low;
}

export fn counting_squarefrees(n: i64) i64 {
    if (n < 1 or n > MAX_N) return -1;
    const limit: usize = @intCast(integer_sqrt(n));
    var mobius: [MAX_ROOT + 1]u8 = @splat(0);
    var composite: [MAX_ROOT + 1]bool = @splat(false);
    for (1..(limit + 1)) |value| mobius[value] = 1;

    for (2..(limit + 1)) |prime| {
        if (composite[prime]) continue;
        if (prime <= limit / prime) {
            var mark_multiple = prime * prime;
            while (mark_multiple <= limit) : (mark_multiple += prime) composite[mark_multiple] = true;
        }
        var factor_multiple = prime;
        while (factor_multiple <= limit) : (factor_multiple += prime) {
            if (mobius[factor_multiple] == 1) mobius[factor_multiple] = 2
            else if (mobius[factor_multiple] == 2) mobius[factor_multiple] = 1;
        }
        if (prime <= limit / prime) {
            const square = prime * prime;
            var square_multiple = square;
            while (square_multiple <= limit) : (square_multiple += square) mobius[square_multiple] = 0;
        }
    }

    var count: i64 = 0;
    for (1..(limit + 1)) |divisor| {
        const d: i64 = @intCast(divisor);
        const quotient = @divTrunc(n, d * d);
        if (mobius[divisor] == 1) count += quotient
        else if (mobius[divisor] == 2) count -= quotient;
    }
    return count;
}
