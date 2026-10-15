export fn maximum_frequency_after_increments(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 257) return -1;
    const budget = input[0];
    const count = length - 1;
    if (budget < 0 or budget > 1_000_000) return -1;
    var values: [256]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < 1 or value > 10_000) return -1;
        var position = index;
        while (position > 0 and values[position - 1] > value) : (position -= 1) {
            values[position] = values[position - 1];
        }
        values[position] = value;
    }
    var left: usize = 0;
    var window_sum: i64 = 0;
    var best: usize = 0;
    for (0..count) |right| {
        window_sum += values[right];
        while (values[right] * @as(i64, @intCast(right - left + 1)) - window_sum > budget) {
            window_sum -= values[left];
            left += 1;
        }
        best = @max(best, right - left + 1);
    }
    return @intCast(best);
}
