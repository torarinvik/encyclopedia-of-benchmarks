fn proper_divisor_sum(value: i64) i64 {
    if (value <= 1) return 0;
    var total: i64 = 1;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@mod(value, divisor) == 0) {
            const partner = @divTrunc(value, divisor);
            total += divisor;
            if (partner != divisor) total += partner;
        }
    }
    return total;
}

export fn problem21_pair_sum(limit: i64) i64 {
    if (limit < 2 or limit > 10000) return -1;
    var total: i64 = 0;
    var smaller: i64 = 2;
    while (smaller < limit) : (smaller += 1) {
        const larger = proper_divisor_sum(smaller);
        if (larger > smaller and proper_divisor_sum(larger) == smaller) {
            total += smaller + larger;
        }
    }
    return total;
}
