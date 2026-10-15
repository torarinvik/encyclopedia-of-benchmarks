export fn smallest_divisor(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 257) return -1;
    const threshold = input[0];
    if (threshold < 1 or threshold > 1_000_000) return -1;
    var maximum: i64 = 0;
    for (1..length) |index| {
        const value = input[index];
        if (value < 1 or value > 1_000_000) return -1;
        maximum = @max(maximum, value);
    }
    const count: i64 = @intCast(length - 1);
    if (threshold < count) return -1;
    var low: i64 = 1;
    var high = maximum;
    while (low < high) {
        const middle = low + @divTrunc(high - low, 2);
        var sum: i64 = 0;
        for (1..length) |index| {
            sum += @divTrunc(input[index] + middle - 1, middle);
        }
        if (sum <= threshold) high = middle else low = middle + 1;
    }
    return low;
}
