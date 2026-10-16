const MAX_LENGTH: usize = 1024;

export fn maximum_subarray_allow_empty(values: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length > 0 and values == null)) return -1;
    for (0..length) |index| {
        if (values[index] < -2147483648 or values[index] > 2147483647) return -1;
    }
    var current: i64 = 0;
    var best: i64 = 0;
    for (0..length) |index| {
        current += values[index];
        if (current < 0) current = 0;
        if (current > best) best = current;
    }
    return best;
}
