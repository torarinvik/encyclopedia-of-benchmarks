export fn problem100(min_total: i64) i64 {
    if (min_total < 0 or min_total > 1_000_000_000_000) return -1;
    var previous_numerator: i64 = 1;
    var previous_denominator: i64 = 0;
    var numerator: i64 = 1;
    var denominator: i64 = 1;
    while (numerator <= 2 * min_total - 1) {
        previous_numerator += 2 * numerator;
        numerator += 2 * previous_numerator;
        previous_denominator += 2 * denominator;
        denominator += 2 * previous_denominator;
    }
    return @divTrunc(denominator + 1, 2);
}
