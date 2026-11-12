fn powerAtMost(base: i64, exponent_input: i64, limit: i64) bool {
    if (base == 0) return true;
    var product: i64 = 1;
    var exponent = exponent_input;
    while (exponent > 0) : (exponent -= 1) {
        if (product > @divTrunc(limit, base)) return false;
        product *= base;
    }
    return true;
}

export fn kth_root_integer(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..2];
    const number = values[0];
    const degree = values[1];
    if (number < 0 or degree < 1 or degree > 64) return -1;

    var low: i64 = 0;
    var high = number;
    while (low < high) {
        const difference = high - low;
        const candidate = low + @divTrunc(difference, 2) + @mod(difference, 2);
        if (powerAtMost(candidate, degree, number)) low = candidate else high = candidate - 1;
    }
    return low;
}
