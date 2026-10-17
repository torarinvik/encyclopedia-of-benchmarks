const MAX_START: i64 = 2166;
const MAX_HIGH_INDEX: i64 = 2167;

fn pentagonal(index: i64) i64 {
    return @divTrunc(index * (3 * index - 1), 2);
}

fn integerSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 20_000;
    while (high - low > 1) {
        const middle = @divTrunc(low + high, 2);
        if (middle * middle <= value) {
            low = middle;
        } else {
            high = middle;
        }
    }
    return low;
}

fn isPentagonal(value: i64) bool {
    const discriminant = 24 * value + 1;
    const root = integerSqrt(discriminant);
    return root * root == discriminant and @mod(root + 1, 6) == 0;
}

pub export fn problem44_start_cursor(start: i64) i64 {
    if (start < 1 or start > MAX_START) return -1;
    var high = start + 1;
    while (high <= MAX_HIGH_INDEX) : (high += 1) {
        const high_value = pentagonal(high);
        var low = high - 1;
        while (low > 0) : (low -= 1) {
            const low_value = pentagonal(low);
            const difference = high_value - low_value;
            const sum = high_value + low_value;
            if (isPentagonal(difference) and isPentagonal(sum)) return difference;
        }
    }
    return -1;
}
