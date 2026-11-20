fn integerSqrtI64(value: i64, upper: i64) i64 {
    var low: i64 = 0;
    var high = upper + 1;
    while (low + 1 < high) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle * middle <= value) low = middle else high = middle;
    }
    return low;
}

export fn fermat_factorization(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..length];
    const number = values[0];
    const max_steps = values[1];
    if (number < 3 or number > 1_000_000_000_000 or @mod(number, 2) == 0
        or max_steps < 0 or max_steps > 4096) return -1;
    var candidate = integerSqrtI64(number, 1_000_000);
    if (candidate * candidate < number) candidate += 1;
    var step: i64 = 0;
    while (step < max_steps) : (step += 1) {
        const difference = candidate * candidate - number;
        const root = integerSqrtI64(difference, candidate);
        if (root * root == difference) {
            const factor = candidate - root;
            if (factor > 1 and factor < number) return factor;
        }
        candidate += 1;
    }
    return 0;
}
