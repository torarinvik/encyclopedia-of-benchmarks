const max_limit: usize = 28_123;

pub export fn problem23(limit: i64) i64 {
    if (limit < 0 or limit > 28_123) return -1;
    const bound: usize = @intCast(limit);
    var proper_divisor_sums: [max_limit + 1]i64 = @splat(0);
    var abundant: [max_limit + 1]bool = @splat(false);
    var representable: [max_limit + 1]bool = @splat(false);

    var divisor: usize = 1;
    while (divisor <= bound / 2) : (divisor += 1) {
        var multiple = 2 * divisor;
        while (multiple <= bound) : (multiple += divisor) {
            proper_divisor_sums[multiple] += @intCast(divisor);
        }
    }
    var value: usize = 12;
    while (value <= bound) : (value += 1) {
        abundant[value] = proper_divisor_sums[value] > @as(i64, @intCast(value));
    }
    var left: usize = 12;
    while (left <= bound) : (left += 1) {
        if (!abundant[left]) continue;
        var right = left;
        while (right <= bound - left) : (right += 1) {
            if (abundant[right]) representable[left + right] = true;
        }
    }

    var total: i64 = 0;
    value = 1;
    while (value <= bound) : (value += 1) {
        if (!representable[value]) total += @intCast(value);
    }
    return total;
}
