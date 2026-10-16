fn divisorCount(value: i64) i64 {
    var remaining = value;
    var factor: i64 = 2;
    var count: i64 = 1;
    while (factor <= @divTrunc(remaining, factor)) : (factor += 1) {
        if (@rem(remaining, factor) == 0) {
            var exponent: i64 = 0;
            while (@rem(remaining, factor) == 0) {
                remaining = @divTrunc(remaining, factor);
                exponent += 1;
            }
            count *= exponent + 1;
        }
    }
    if (remaining > 1) count *= 2;
    return count;
}

export fn problem12(minimum_divisors: i64) i64 {
    if (minimum_divisors < 0 or minimum_divisors > 500) return -1;
    var index: i64 = 1;
    while (index <= 12_375) : (index += 1) {
        var left = index;
        var right = index + 1;
        if (@rem(index, 2) == 0) {
            left = @divTrunc(left, 2);
        } else {
            right = @divTrunc(right, 2);
        }
        if (divisorCount(left) * divisorCount(right) >= minimum_divisors)
            return @divTrunc(index * (index + 1), 2);
    }
    return -1;
}
