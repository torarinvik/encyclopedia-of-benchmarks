const MAX_DENOMINATOR: i64 = 12_000;

fn gcd(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @mod(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

pub export fn problem73(max_denominator: i64) i64 {
    if (max_denominator < 0 or max_denominator > MAX_DENOMINATOR) return -1;
    var count: i64 = 0;
    var denominator: i64 = 0;
    while (denominator <= max_denominator) : (denominator += 1) {
        var numerator_start = @divTrunc(denominator, 3) + 1;
        var numerator_step: i64 = 1;
        if (@mod(denominator, 2) == 0) {
            numerator_start += 1 - @mod(numerator_start, 2);
            numerator_step = 2;
        }
        const numerator_end = @divTrunc(denominator + 1, 2);
        var numerator = numerator_start;
        while (numerator < numerator_end) : (numerator += numerator_step) {
            if (gcd(numerator, denominator) == 1) count += 1;
        }
    }
    return count;
}
