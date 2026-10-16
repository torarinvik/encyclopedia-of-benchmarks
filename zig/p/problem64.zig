const MAX_LIMIT: i64 = 10_000;

fn integerSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high = value + 1;
    while (high - low > 1) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle <= @divTrunc(value, middle)) low = middle else high = middle;
    }
    return low;
}

fn periodLength(value: i64, root: i64) i64 {
    var numerator: i64 = 0;
    var denominator: i64 = 1;
    var coefficient = root;
    var period: i64 = 0;
    while (true) {
        numerator = denominator * coefficient - numerator;
        denominator = @divTrunc(value - numerator * numerator, denominator);
        coefficient = @divTrunc(root + numerator, denominator);
        period += 1;
        if (coefficient == 2 * root) break;
    }
    return period;
}

pub export fn problem64(inclusive_limit: i64) i64 {
    if (inclusive_limit < 0 or inclusive_limit > MAX_LIMIT) return -1;
    var count: i64 = 0;
    var value: i64 = 2;
    while (value <= inclusive_limit) : (value += 1) {
        const root = integerSqrt(value);
        if (root * root != value and @mod(periodLength(value, root), 2) == 1) count += 1;
    }
    return count;
}
