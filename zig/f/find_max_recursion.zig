const MAX_LENGTH: usize = 256;

fn findMaxRange(values: [*]const i64, low: usize, high: usize) i64 {
    if (low == high) return values[low];
    const middle = low + (high - low) / 2;
    const left = findMaxRange(values, low, middle);
    const right = findMaxRange(values, middle + 1, high);
    return if (left >= right) left else right;
}

export fn find_max_recursion(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return -1;
    for (0..length) |i| if (values[i] < -2147483648 or values[i] > 2147483647) return -1;
    return findMaxRange(values, 0, length - 1);
}
