const max_n: i64 = 1_000_005;

export fn smallest_prime_factor(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length != 1) return -1;
    const n = values[0];
    if (n < 2 or n > max_n) return -1;
    var factor: i64 = 2;
    while (factor <= @divTrunc(n, factor)) : (factor += 1) {
        if (@rem(n, factor) == 0) return factor;
    }
    return n;
}
