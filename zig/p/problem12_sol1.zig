fn divisorCount(value: i64) i64 {
    var remaining = value;
    var factor: i64 = 2;
    var count: i64 = 1;
    while (factor <= @divTrunc(remaining, factor)) : (factor += 1) {
        var multiplicity: i64 = 0;
        while (@rem(remaining, factor) == 0) {
            remaining = @divTrunc(remaining, factor);
            multiplicity += 1;
        }
        if (multiplicity > 0) count *= multiplicity + 1;
    }
    if (remaining > 1) count *= 2;
    return count;
}

export fn problem12_sol1(threshold: i64) i64 {
    if (threshold != 500) return -1;
    var index: i64 = 1;
    var triangular: i64 = 1;
    while (true) {
        index += 1;
        triangular += index;
        if (divisorCount(triangular) > 500) return triangular;
    }
}
