export fn is_monotonic(values: ?[*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    if (values == null) return if (length == 0) 1 else -1;
    const items = values.?;

    for (1..length) |i| {
        if (items[i - 1] > items[i]) {
            for (1..length) |j| {
                if (items[j - 1] < items[j]) return 0;
            }
            return 1;
        }
    }
    return 1;
}
