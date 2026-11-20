/// Decide whether the iterated Euler-totient chain sums to n.
export fn perfect_totient_number(n: i64) i64 {
    if (n < 3 or n > 65535) return -1;
    var value = n;
    var total: i64 = 0;
    while (value > 1) {
        var result = value;
        var remaining = value;
        var factor: i64 = 2;
        while (factor <= @divTrunc(remaining, factor)) : (factor += 1) {
            if (@mod(remaining, factor) == 0) {
                while (@mod(remaining, factor) == 0) {
                    remaining = @divTrunc(remaining, factor);
                }
                result -= @divTrunc(result, factor);
            }
        }
        if (remaining > 1) result -= @divTrunc(result, remaining);
        value = result;
        total += value;
    }
    return if (total == n) 1 else 0;
}
