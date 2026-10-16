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

export fn problem21(limit: i64) i64 {
    if (limit < 1 or limit > 10000) return -1;
    var total: i64 = 0;
    var value: i64 = 1;
    while (value < limit) : (value += 1) {
        const partner = proper_divisor_sum(value);
        if (partner != value and proper_divisor_sum(partner) == value) total += value;
    }
    return total;
}
