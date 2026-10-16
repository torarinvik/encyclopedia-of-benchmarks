const MAX_INDEX: i64 = 27_693;

fn integerSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 200_000;
    while (high - low > 1) {
        const middle = (low + high) / 2;
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

pub export fn problem45(start: i64) i64 {
    if (start < 0 or start > MAX_INDEX) return -1;
    var index = start;
    while (index <= MAX_INDEX) : (index += 1) {
        const value = index * (2 * index - 1);
        if (isPentagonal(value)) return value;
    }
    return -1;
}
